#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Discovery - 4d4y 论坛终端客户端
使用 urwid 构建 TUI 界面，支持 ueberzugpp 图片预览

用法:
    python Discovery.py              # 普通模式
    python Discovery.py -p           # 启用 ueberzugpp 图片预览
    python Discovery.py --preview    # 同上
"""

import urwid
import requests
import re
import time
import os
import sys
import json
import argparse
import getpass
import subprocess
import tempfile
import hashlib
import urllib.parse
from bs4 import BeautifulSoup
import lxml.html
import ssl
from requests.adapters import HTTPAdapter
from urllib3.poolmanager import PoolManager

# 禁用 SSL 警告
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# ─── 常量配置 ────────────────────────────────────────────────────────────

LOGIN_FILE = os.path.expanduser('~/.4d4y-login')

KEY_ENTER        = ['enter', 'right', 'l']
KEY_BACK         = ['esc', 'backspace', 'left', 'h']
KEY_REFRESH      = ['r']
KEY_QUIT         = ['q']

PALETTE = [
    ('header',     'light gray',       'black'),
    ('footer',     'light green',      'black'),
    ('focus',      'black',            'white', 'bold'),
    ('normal',     'white',            'black'),
    ('highlight',  'yellow',           'black', 'bold'),
    ('img_badge',  'dark cyan',        'black'),
    ('error',      'light red',        'black'),
]

# ─── 辅助类 ──────────────────────────────────────────────────────────────


class AttributeDict(dict):
    __getattr__ = dict.__getitem__
    __setattr__ = dict.__setitem__


class SSLAdapter(HTTPAdapter):
    """跳过 SSL 证书验证的适配器"""
    def init_poolmanager(self, *args, **kwargs):
        kwargs['ssl_context'] = self.create_ssl_context()
        return super().init_poolmanager(*args, **kwargs)

    def create_ssl_context(self):
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE
        return ctx


# ─── 登录凭证管理 ─────────────────────────────────────────────────────────


def load_credentials():
    """从 ~/.4d4y-login 加载已保存的登录凭证

    Returns:
        (username, password) 元组，默认都为空字符串
    """
    try:
        if os.path.exists(LOGIN_FILE):
            with open(LOGIN_FILE, 'r', encoding='utf-8') as f:
                lines = f.read().strip().split('\n')
                if len(lines) >= 2:
                    return lines[0].strip(), lines[1].strip()
    except Exception:
        pass
    return '', ''


def save_credentials(username, password):
    """保存登录凭证到 ~/.4d4y-login（权限 600）"""
    try:
        login_dir = os.path.dirname(LOGIN_FILE)
        if login_dir and not os.path.exists(login_dir):
            os.makedirs(login_dir, exist_ok=True)
        with open(LOGIN_FILE, 'w', encoding='utf-8') as f:
            f.write(f"{username}\n{password}\n")
        os.chmod(LOGIN_FILE, 0o600)
    except Exception as e:
        print(f"  警告: 无法保存凭证 - {e}")


def prompt_credentials():
    """交互式提示用户输入登录信息

    Returns:
        (username, password) 元组
    """
    print()
    username = input("  用户名: ").strip()
    password = ''
    if username:
        password = getpass.getpass("  密  码: ").strip()
        save = input("  保存登录信息? [Y/n]: ").strip().lower()
        if save != 'n':
            save_credentials(username, password)
            print(f"  已保存到 {LOGIN_FILE}")
    print()
    return username, password


# ─── 图片管理器 ────────────────────────────────────────────────────────────


class ImageManager:
    """使用 ueberzugpp 在终端中显示帖子图片

    通过子进程 stdin/stdout 发送 JSON 命令与 ueberzugpp 通信。
    图片区域位于终端右下角（约 45% 宽 × 40% 高），
    随着帖子切换自动更新。
    """

    IDENTIFIER = 'discovery_img'

    def __init__(self):
        self.process = None
        self.enabled = False
        self.visible = False
        self.show_preview = True
        self.showing_original = False
        self.temp_dir = tempfile.mkdtemp(prefix='discovery_img_')

        # 独立的 HTTP session 用于下载图片
        self.session = requests.Session()
        self.session.headers.update({
            "User-Agent": (
                "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
                "AppleWebKit/537.36 (KHTML, like Gecko) "
                "Chrome/120.0.0.0 Safari/537.36"
            ),
            "Referer": "https://www.4d4y.com/",
        })
        self.session.mount('https://', SSLAdapter())

        self.current_images = []
        self.current_index = 0
        self._last_post_id = None

    # ── 生命周期 ──

    def init_canvas(self):
        """启动 ueberzugpp 子进程，返回是否成功"""
        if self.enabled:
            return True
        try:
            self.process = subprocess.Popen(
                ['ueberzugpp', 'layer', '-p', 'json'],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.DEVNULL,
                bufsize=0,
            )
            self.enabled = True
            return True
        except FileNotFoundError:
            print("  错误: 未找到 ueberzugpp，请先安装")
            print("  https://github.com/ueberzug/ueberzugpp")
        except Exception as e:
            print(f"  错误: ueberzugpp 启动失败 - {e}")
        return False

    def cleanup(self):
        """清除所有图片并释放资源"""
        self.clear()
        if self.process:
            try:
                self._send_json({"action": "quit"})
                self.process.stdin.close()
                self.process.wait(timeout=2)
            except Exception:
                try:
                    self.process.kill()
                except Exception:
                    pass
            self.process = None
        # 清理临时文件
        try:
            for fname in os.listdir(self.temp_dir):
                fpath = os.path.join(self.temp_dir, fname)
                if os.path.isfile(fpath):
                    os.remove(fpath)
            os.rmdir(self.temp_dir)
        except Exception:
            pass

    # ── ueberzugpp JSON 通信 ──

    def _send_json(self, data):
        """向 ueberzugpp 子进程发送一条 JSON 命令"""
        if not self.process or self.process.poll() is not None:
            self.enabled = False
            return
        try:
            line = json.dumps(data, ensure_ascii=False) + '\n'
            self.process.stdin.write(line.encode('utf-8'))
            self.process.stdin.flush()
            # 非阻塞读走 stdout 的响应，防止缓冲区满
        except (BrokenPipeError, OSError):
            self.enabled = False

    def _drain_stdout(self):
        """非阻塞读空 ueberzugpp stdout，防止缓冲区满导致阻塞"""
        if not self.process or self.process.poll() is not None:
            return
        try:
            import select
            while True:
                ready, _, _ = select.select([self.process.stdout], [], [], 0)
                if not ready:
                    break
                self.process.stdout.read(4096)
        except Exception:
            pass

    # ── 图片下载 ──

    def download_image(self, url):
        """下载图片到临时目录，返回本地路径（失败返回 None）"""
        url_hash = hashlib.md5(url.encode()).hexdigest()[:12]

        path_lower = url.lower().split('?')[0].split('#')[0]
        if '.png' in path_lower:
            ext = '.png'
        elif '.gif' in path_lower:
            ext = '.gif'
        elif '.webp' in path_lower:
            ext = '.webp'
        elif '.bmp' in path_lower:
            ext = '.bmp'
        else:
            ext = '.jpg'

        local_path = os.path.join(self.temp_dir, f'{url_hash}{ext}')

        if os.path.exists(local_path) and os.path.getsize(local_path) > 100:
            return local_path

        try:
            r = self.session.get(url, verify=False, timeout=30, stream=True)
            if r.status_code == 200:
                content = r.content
                if len(content) < 100:
                    return None
                with open(local_path, 'wb') as f:
                    f.write(content)
                return local_path
        except Exception:
            pass
        return None

    # ── 显示控制 ──

    def update_display(self, images, post_id, terminal_size):
        """根据当前帖子更新图片显示"""
        if not self.show_preview or not self.enabled:
            self.clear()
            return

        if post_id == self._last_post_id and self.visible:
            return

        self._last_post_id = post_id
        self.showing_original = False
        self._remove_image()

        if not images:
            return

        self.current_images = images
        self.current_index = 0
        self._show_current(terminal_size)

    def _show_current(self, terminal_size):
        """显示 current_images[current_index] 对应的图片（默认缩略图）"""
        if not self.current_images or not self.enabled:
            return

        img_info = self.current_images[self.current_index]
        url = img_info['original'] if self.showing_original else img_info['thumb']
        path = self.download_image(url)
        if not path:
            fallback = img_info['thumb'] if self.showing_original else img_info['original']
            if fallback != url:
                path = self.download_image(fallback)

        if not path:
            self.visible = False
            return

        tw, th = terminal_size
        if self.showing_original:
            # 原图模式：占满整个终端（留顶部1行给状态栏）
            img_max_w = tw
            img_max_h = th - 1
            img_x = 0
            img_y = 1
        else:
            # 缩略图模式：终端右下角 45% × 40%
            img_max_w = max(20, int(tw * 0.45))
            img_max_h = max(10, int(th * 0.4))
            img_x = tw - img_max_w
            img_y = th - img_max_h

        self._send_json({
            "action": "add",
            "identifier": self.IDENTIFIER,
            "x": img_x,
            "y": img_y,
            "max_width": img_max_w,
            "max_height": img_max_h,
            "path": os.path.abspath(path),
            "scaler": "contain",
        })
        self._drain_stdout()
        self.visible = True

    def _remove_image(self):
        """发送 remove 命令移除当前图片"""
        self._send_json({
            "action": "remove",
            "identifier": self.IDENTIFIER,
        })
        self._drain_stdout()
        self.visible = False

    def cycle_next(self, terminal_size):
        """切换到下一张图片"""
        if not self.current_images or not self.enabled:
            return
        self.showing_original = False
        self.current_index = (self.current_index + 1) % len(self.current_images)
        self._remove_image()
        self._show_current(terminal_size)

    def cycle_prev(self, terminal_size):
        """切换到上一张图片"""
        if not self.current_images or not self.enabled:
            return
        self.showing_original = False
        self.current_index = (self.current_index - 1) % len(self.current_images)
        self._remove_image()
        self._show_current(terminal_size)

    def toggle_original(self, terminal_size):
        """在缩略图/原图之间切换"""
        if not self.current_images or not self.enabled or not self.visible:
            return
        self.showing_original = not self.showing_original
        self._remove_image()
        self._show_current(terminal_size)

    def toggle_preview(self):
        """开关图片预览，返回当前是否开启"""
        self.show_preview = not self.show_preview
        if not self.show_preview:
            self.clear()
        return self.show_preview

    def clear(self):
        """清除图片显示并重置帖子跟踪"""
        if self.visible and self.enabled:
            self._remove_image()
        self._last_post_id = None

    @property
    def image_info(self):
        """返回状态栏图片信息文本"""
        if not self.current_images:
            return ""
        total = len(self.current_images)
        idx = self.current_index + 1
        if not self.show_preview:
            return "[image preview OFF] p=on"
        if not self.visible:
            return f"[image {idx}/{total}] Tab=next p=off"
        mode = '原图' if self.showing_original else '缩略图'
        return f"[image {idx}/{total} {mode}] Tab=next Enter=原图 p=off"


# ─── 论坛 API ────────────────────────────────────────────────────────────


class Forum:
    """4d4y 论坛 API 封装"""

    HP_URL             = 'https://www.4d4y.com/forum/'
    LOGIN_URL          = HP_URL + 'logging.php?action=login'
    LOGIN_SUBMIT_URL   = HP_URL + 'logging.php?action=login&loginsubmit=yes'
    DISPLAY_URL        = HP_URL + 'forumdisplay.php?fid=2&page=%d'
    THREAD_URL         = HP_URL + 'viewthread.php?tid=%d&page=%d'
    SEARCH_URL         = HP_URL + 'search.php?srchtype=title&srchtxt=%s&searchsubmit=true&orderby=lastpost&ascdesc=desc&srchfid[0]=2&page=%d'
    POST_URL           = HP_URL + 'post.php?action=%s'

    TID_RE       = re.compile(r'tid=(\d+)')
    USER_RE      = re.compile(r'uid=(\d+)')
    POST_RE      = re.compile(r'post_([0-9]+)')
    POST_DATE_RE = re.compile(r'发表于\s*([\w\W]+)')
    FORMHASH_RE  = re.compile(r'name="formhash"\s+value="([^"]*)"')

    # 需要跳过的小图 URL 特征（表情、头像、图标等）
    SKIP_IMG_PATTERNS = re.compile(
        r'(smiley|static/image/common|static/image/smiley|'
        r'forumimages|avatar|rank|icon_\w+|star|group_\d|'
        r'static/image/attach)',
        re.IGNORECASE,
    )

    HEADERS = {
        "User-Agent": (
            "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
            "AppleWebKit/537.36 (KHTML, like Gecko) "
            "Chrome/120.0.0.0 Safari/537.36"
        ),
        "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
        "Accept-Language": "zh-CN,zh;q=0.9,en;q=0.8",
        "Cache-Control": "max-age=0",
        "Content-Type": "application/x-www-form-urlencoded",
    }

    def __init__(self, username, password):
        self.username = username
        self.password = password
        self.session = requests.Session()
        self.session.headers.update(self.HEADERS)
        self.session.mount('https://', SSLAdapter())

    # ── 登录 ──

    def login(self):
        """登录论坛，返回是否成功"""
        try:
            r = self.session.get(self.LOGIN_URL, verify=False, timeout=30)
            r.encoding = 'gb18030'

            formhash = "58734250"
            m = self.FORMHASH_RE.search(r.text)
            if m:
                formhash = m.group(1)

            payload = {
                'formhash':    formhash,
                'loginfield':  'username',
                'username':    self.username,
                'password':    self.password,
                'questionid':  '0',
                'answer':      '',
                'loginsubmit': 'true',
                'referer':     'index.php',
            }

            resp = self.session.post(
                self.LOGIN_SUBMIT_URL,
                data=payload,
                allow_redirects=True,
                verify=False,
                timeout=30,
            )
            resp.encoding = 'gb18030'

            if "欢迎您回来" in resp.text:
                return True
            return False
        except Exception as e:
            print(f"  登录错误: {e}")
            return False

    # ── 帖子列表 ──

    def display(self, page=1):
        """获取论坛帖子列表

        Returns:
            (records, pages, threads) 三元组
        """
        try:
            r = self.session.get(self.DISPLAY_URL % page, verify=False, timeout=30)
            r.encoding = 'gb18030'
            soup = BeautifulSoup(r.text, 'html.parser')

            threads = self._extract_threads(soup)
            pages = self._extract_pages(soup)
            return len(threads), pages, threads
        except Exception:
            return 0, 1, []

    # ── 搜索 ──

    def search(self, title, page=1):
        """按标题搜索帖子

        Returns:
            (records, pages, threads) 三元组
        """
        try:
            encoded = urllib.parse.quote(title)
            r = self.session.get(self.SEARCH_URL % (encoded, page), verify=False, timeout=30)
            r.encoding = 'gb18030'
            soup = BeautifulSoup(r.text, 'html.parser')

            # 优先使用与帖子列表相同的解析逻辑
            threads = self._extract_threads(soup)

            # 如果标准解析无结果，尝试搜索结果页的特定格式
            if not threads:
                threads = self._extract_search_results(soup)

            pages = self._extract_pages(soup)
            return len(threads), pages, threads
        except Exception:
            return 0, 1, []

    # ── 查看帖子 ──

    def viewthread(self, tid, page=1, authorid=None):
        """查看帖子详情及回复

        Returns:
            (pages, posts) 元组
        """
        try:
            url = self.THREAD_URL % (tid, page)
            if authorid:
                url += f"&authorid={authorid}"

            r = self.session.get(url, verify=False, timeout=30)
            r.encoding = 'gb18030'
            soup = BeautifulSoup(r.text, 'html.parser')

            pages = self._extract_pages(soup)

            posts = []
            for post_div in soup.find_all('div', id=re.compile(r'post_\d+')):
                try:
                    post_id_match = self.POST_RE.match(post_div.get('id', ''))
                    if not post_id_match:
                        continue
                    post_id = int(post_id_match.group(1))

                    author_td = post_div.find('td', class_='postauthor')
                    if not author_td:
                        continue

                    # ── 作者信息 ──
                    author_link = author_td.find('a')
                    author_name = "未知"
                    author_id = 0
                    if author_link:
                        author_name = author_link.get_text(strip=True)
                        uid_match = self.USER_RE.search(author_link.get('href', ''))
                        if uid_match:
                            author_id = int(uid_match.group(1))

                    # ── 帖子内容与图片 ──
                    content_td = post_div.find('td', class_='t_msgfont')
                    content = ""
                    images = []

                    if content_td:
                        # 先提取图片（在移除引用之前）
                        images = self._extract_images(content_td)

                        # 复制内容节点以避免修改原始 soup
                        content_copy = content_td

                        # 移除附件下载标记（如 [下载(566.6 KB)...]）
                        self._clean_attach_text(content_copy)

                        for quote in content_copy.find_all(
                            ['div', 'blockquote'],
                            class_=['quote', 'blockquote'],
                        ):
                            quote.decompose()
                        content = content_copy.get_text(strip=True)[:1000]
                        # 最终文本级清理：移除残留的 [下载...] 标记
                        content = re.sub(r'\[下载[^\]]*\]\s*\d{4}[-/]\d{1,2}[-/]\d{1,2}\s+\d{1,2}:\d{2}', '', content)
                        content = re.sub(r'\[下载[^\]]*\]', '', content)
                        content = re.sub(r'\s{2,}', ' ', content).strip()
                        if not content:
                            content = "作者被禁止或删除 内容自动屏蔽"

                    # ── 楼层编号 ──
                    level = 1
                    level_link = post_div.find('a', id=f'postnum{post_id}')
                    if level_link:
                        lt = level_link.get_text(strip=True)
                        if lt.isdigit():
                            level = int(lt)

                    # ── 日期 ──
                    date = time.localtime()
                    author_info = post_div.find('div', class_='authorinfo')
                    if author_info:
                        em = author_info.find('em')
                        if em:
                            date_text = em.get_text(strip=True)
                            date_match = self.POST_DATE_RE.search(date_text)
                            if date_match:
                                try:
                                    date = time.strptime(
                                        date_match.group(1).strip(),
                                        '%Y-%m-%d %H:%M',
                                    )
                                except ValueError:
                                    pass

                    posts.append(AttributeDict({
                        'level':  level,
                        'author': AttributeDict({
                            'name': author_name,
                            'id':   author_id,
                        }),
                        'content': content,
                        'id':      post_id,
                        'images':  images,
                        'date':    time.strftime("%m-%d %H:%M", date),
                        'reply':   None,
                    }))
                except Exception:
                    continue

            return pages, posts
        except Exception:
            return 1, []

    # ── 回复 ──

    def reply(self, msg, tid):
        """回复指定帖子，返回是否成功

        Args:
            msg: 回复内容
            tid: 帖子 ID
        """
        try:
            # 先从帖子页获取 formhash
            r = self.session.get(
                self.THREAD_URL % (tid, 1), verify=False, timeout=30,
            )
            r.encoding = 'gb18030'

            m = self.FORMHASH_RE.search(r.text)
            if not m:
                return False
            formhash = m.group(1)

            payload = {
                'formhash': formhash,
                'message':  msg,
                'subject':  '',
                'usesig':   '1',
            }

            resp = self.session.post(
                self.POST_URL % ('reply&tid=%d' % tid),
                data=payload,
                verify=False,
                timeout=30,
            )
            resp.encoding = 'gb18030'

            return "回复成功" in resp.text or "发帖成功" in resp.text
        except Exception:
            return False

    # ── 内部方法 ──

    def _extract_threads(self, soup):
        """从 soup 解析帖子列表（通用）"""
        threads = []
        for row in soup.find_all('tbody', id=re.compile(r'normalthread_\d+')):
            try:
                subject_th = row.find('th', class_='subject')
                if not subject_th:
                    continue

                title_link = subject_th.find('a')
                if not title_link:
                    continue

                title = title_link.get_text(strip=True)
                tid_match = self.TID_RE.search(title_link.get('href', ''))
                if not tid_match:
                    continue
                tid = int(tid_match.group(1))

                # 作者
                author_td = row.find('td', class_='author')
                author_name = "未知"
                author_id = 0
                if author_td:
                    author_link = author_td.find('a')
                    if author_link:
                        author_name = author_link.get_text(strip=True)
                        uid_m = self.USER_RE.search(author_link.get('href', ''))
                        if uid_m:
                            author_id = int(uid_m.group(1))

                # 回复 / 浏览数
                replys = 0
                reviews = 0
                nums_td = row.find('td', class_='nums')
                if nums_td:
                    strong = nums_td.find('strong')
                    if strong and strong.get_text(strip=True).isdigit():
                        replys = int(strong.get_text(strip=True))
                    em = nums_td.find('em')
                    if em and em.get_text(strip=True).isdigit():
                        reviews = int(em.get_text(strip=True))

                threads.append(AttributeDict({
                    'title': title,
                    'id': tid,
                    'replys': replys,
                    'reviews': reviews,
                    'author': AttributeDict({
                        'id': author_id,
                        'name': author_name,
                    }),
                }))
            except Exception:
                continue
        return threads

    def _extract_search_results(self, soup):
        """解析搜索结果页的特定格式（备用）"""
        threads = []
        seen_tids = set()
        for el in soup.find_all(['li', 'tr', 'div']):
            link = el.find('a', href=re.compile(r'tid=(\d+)'))
            if not link:
                # 也匹配 thread-xxx-1-1.html 风格
                link = el.find('a', href=re.compile(r'thread-\d+-\d+-\d+\.html'))
            if not link:
                continue

            title_text = link.get_text(strip=True)
            if not title_text or len(title_text) > 200:
                continue

            tid_match = self.TID_RE.search(link.get('href', ''))
            if not tid_match:
                continue
            tid = int(tid_match.group(1))
            if tid in seen_tids:
                continue
            seen_tids.add(tid)

            # 尝试提取作者
            author_name = ""
            author_el = el.find('a', href=re.compile(r'uid=(\d+)'))
            if author_el:
                author_name = author_el.get_text(strip=True)

            threads.append(AttributeDict({
                'title': title_text,
                'id': tid,
                'replys': 0,
                'reviews': 0,
                'author': AttributeDict({'id': 0, 'name': author_name}),
            }))
        return threads

    def _extract_pages(self, soup):
        """从 soup 解析总页数"""
        pages = 1
        pages_div = soup.find('div', class_='pages')
        if pages_div:
            for link in pages_div.find_all('a'):
                text = link.get_text(strip=True)
                if text.isdigit():
                    pages = max(pages, int(text))
        return pages

    # 匹配 onclick="zoom(this, 'ORIGINAL_URL')" 中的原图地址
    ZOOM_RE = re.compile(r"""zoom\(this,\s*['"]([^'"]+)['"]""")

    def _should_skip_img(self, img_tag):
        """判断 <img> 是否应跳过（表情、图标等）"""
        src = img_tag.get('src', '')
        if not src or src.startswith('data:'):
            return True
        if self.SKIP_IMG_PATTERNS.search(src):
            return True
        css_class = ' '.join(img_tag.get('class', []))
        if 'smiley' in css_class.lower() or 'vmiddle' in css_class.lower():
            return True
        w = img_tag.get('width', '')
        h = img_tag.get('height', '')
        if w in ('1', '0') or h in ('1', '0'):
            return True
        return False

    def _resolve_img_src(self, img_tag):
        """从 <img> 标签中提取缩略图和原图 URL

        Returns:
            {'thumb': thumbnail_url, 'original': original_url}
            如果无法区分则两者相同；应跳过则返回 None
        """
        if self._should_skip_img(img_tag):
            return None

        src_raw = img_tag.get('src', '')
        if not src_raw:
            return None

        # 从 onclick="zoom(this, 'ORIGINAL_URL')" 提取原图
        original = None
        onclick = img_tag.get('onclick', '')
        if onclick:
            m = self.ZOOM_RE.search(onclick)
            if m:
                original = m.group(1)

        # 原图还可能在 file / zoomfile 等属性中
        if not original:
            original = (
                img_tag.get('zoomfile') or
                img_tag.get('file') or
                img_tag.get('data-original') or
                img_tag.get('data-src') or
                img_tag.get('data-file') or
                None
            )

        # src 是缩略图；如果没有独立原图则 src 本身就是原图
        thumb = src_raw
        if not original:
            original = src_raw

        # 补全相对 URL
        if not thumb.startswith('http'):
            thumb = urllib.parse.urljoin(self.HP_URL, thumb)
        if not original.startswith('http'):
            original = urllib.parse.urljoin(self.HP_URL, original)

        return {'thumb': thumb, 'original': original}

    def _extract_images(self, content_td):
        """从帖子内容中提取图片（返回 [{'thumb':.., 'original':..}, ...]）

        包括两种来源：
        1. 帖子正文中的 <img> 标签
        2. 附件区块中的图片
        """
        images = []
        seen_originals = set()
        if not content_td:
            return images

        def _add(img_info):
            if img_info and img_info['original'] not in seen_originals:
                seen_originals.add(img_info['original'])
                images.append(img_info)

        # ── 来源 1：正文中的 <img> 标签 ──
        for img_tag in content_td.find_all('img'):
            _add(self._resolve_img_src(img_tag))

        # ── 来源 2：附件区块（Discuz 附件图片） ──
        for selector in [
            'div.t_attachlist', 'div.attachnew',
            'div.t_attachlist_admin', 'div.attachedimage',
            'table.t_attachlist',
        ]:
            for attach_div in content_td.select(selector):
                for img_tag in attach_div.find_all('img'):
                    _add(self._resolve_img_src(img_tag))

        return images

    @staticmethod
    def _clean_attach_text(content_td):
        """移除附件下载标记文本，如 [下载(566.6 KB)2026-4-20 09:52]"""
        if not content_td:
            return

        # 移除附件容器
        for selector in [
            'div.t_attachlist',
            'div.attachnew',
            'div.t_attachlist_admin',
            'div.attachedimage',
            'table.t_attachlist',
        ]:
            for el in content_td.select(selector):
                el.decompose()

        # 移除残留的 [下载...] 下载链接
        ATTACH_RE = re.compile(r'\[下载[^\]]*\]', re.DOTALL)
        # 只处理顶层文本节点，避免误删正文中本来就有 [下载...] 的情况
        # 这里直接对整个 content_td 的文本做替换已经足够安全
        for el in content_td.find_all(string=ATTACH_RE):
            el.replace_with('')


# ─── UI 组件 ──────────────────────────────────────────────────────────────


class VimListBoxMixin:
    """Vim 风格按键混入类"""

    def handle_vim_keys(self, size, key):
        """处理 Vim 风格按键，返回 True 表示已处理"""
        current_focus = self.focus_position
        if current_focus is None:
            return False

        if key == 'j':
            if current_focus < len(self.walker) - 1:
                self.set_focus(current_focus + 1)
            elif current_focus >= len(self.walker) - 1:
                if hasattr(self, 'load_more'):
                    self.load_more()
                    if current_focus < len(self.walker) - 1:
                        self.set_focus(current_focus + 1)
            return True

        if key == 'k':
            if current_focus > 0:
                self.set_focus(current_focus - 1)
            return True

        if key == 'ctrl d':
            half = max(1, (size[1] if len(size) > 1 else 24) // 2)
            self.set_focus(min(len(self.walker) - 1, current_focus + half))
            self._invalidate()
            return True

        if key == 'ctrl u':
            half = max(1, (size[1] if len(size) > 1 else 24) // 2)
            self.set_focus(max(0, current_focus - half))
            self._invalidate()
            return True

        return False


class ThreadItemWidget(urwid.WidgetWrap):
    """帖子列表单行组件"""

    def __init__(self, thread, highlight=''):
        self.thread = thread

        author_text = thread.author.name
        title_text = thread.title
        if highlight:
            if highlight.lower() in author_text.lower():
                author_text = ('highlight', author_text)
            if highlight.lower() in title_text.lower():
                title_text = ('highlight', title_text)

        columns = urwid.Columns([
            (15, urwid.Padding(urwid.Text(author_text), align='right', width='pack')),
            (1, urwid.Text('|')),
            ('weight', 1, urwid.Text(title_text)),
        ], dividechars=0)

        super().__init__(urwid.AttrMap(columns, 'normal', 'focus'))


class ThreadListBox(VimListBoxMixin, urwid.ListBox):
    """帖子列表（支持无限滚动加载）"""

    def __init__(self, on_next_page):
        self.on_next_page = on_next_page
        self.threads = []
        self.widgets = []
        self.page = 0
        self.pages = 1
        self.records = 0
        self.loading = False
        self.last_focus = 0

        self.walker = urwid.SimpleFocusListWalker([])
        super().__init__(self.walker)
        self.load_more()

    def load_more(self):
        if self.loading or self.page >= self.pages:
            return
        self.loading = True
        self.page += 1
        self.records, self.pages, new_threads = self.on_next_page('', self.page)

        for thread in new_threads:
            self.threads.append(thread)
            widget = ThreadItemWidget(thread)
            self.widgets.append(widget)
            self.walker.append(widget)

        self.loading = False

    def keypress(self, size, key):
        if self.handle_vim_keys(size, key):
            return None

        cf = self.focus_position

        if key == 'up':
            if cf is not None and cf > 0:
                self.focus_position = cf - 1
            return None
        if key == 'down':
            if cf is not None and cf < len(self.walker) - 1:
                self.focus_position = cf + 1
            elif cf is not None and cf >= len(self.walker) - 1:
                self.load_more()
                if cf < len(self.walker) - 1:
                    self.focus_position = cf + 1
            return None
        if key == 'page up':
            if cf is not None:
                self.focus_position = max(0, cf - 20)
            return None
        if key == 'page down':
            if cf is not None:
                self.focus_position = min(len(self.walker) - 1, cf + 20)
            return None
        if key == 'home':
            if self.walker:
                self.focus_position = 0
            return None
        if key == 'end':
            if self.walker:
                self.focus_position = len(self.walker) - 1
            return None

        return super().keypress(size, key)


class PostItemWidget(urwid.WidgetWrap):
    """帖子回复单行组件"""

    def __init__(self, index, post):
        author_widget = urwid.Text(post.author.name)
        content_text = post.content[:200] + ('...' if len(post.content) > 200 else '')
        content_widget = urwid.Text(content_text)
        date_widget = urwid.Text(post.date)

        columns = urwid.Columns([
            (12, urwid.Padding(author_widget, align='right', width='pack')),
            (1, urwid.Text('|')),
            ('weight', 1, content_widget),
            (1, urwid.Text('|')),
            (12, urwid.Padding(date_widget, align='left', width='pack')),
        ], dividechars=0)

        super().__init__(urwid.AttrMap(columns, 'normal', 'focus'))


class PostListBox(VimListBoxMixin, urwid.ListBox):
    """帖子回复列表（支持无限滚动加载）"""

    def __init__(self, tid, on_next_page, authorid=None):
        self.tid = tid
        self.authorid = authorid
        self.on_next_page = on_next_page
        self.posts = []
        self.widgets = []
        self.page = 0
        self.pages = 1
        self.loading = False

        self.walker = urwid.SimpleFocusListWalker([])
        super().__init__(self.walker)
        self.load_more()

    def load_more(self):
        if self.loading or self.page >= self.pages:
            return
        self.loading = True
        self.page += 1
        self.pages, new_posts = self.on_next_page(self.tid, self.page, self.authorid)

        start_idx = len(self.posts) + 1
        for i, post in enumerate(new_posts):
            self.posts.append(post)
            widget = PostItemWidget(start_idx + i, post)
            self.widgets.append(widget)
            self.walker.append(widget)

        self.loading = False

    def keypress(self, size, key):
        if self.handle_vim_keys(size, key):
            return None

        cf = self.focus_position

        if key == 'up':
            if cf is not None and cf > 0:
                self.focus_position = cf - 1
            return None
        if key == 'down':
            if cf is not None and cf < len(self.walker) - 1:
                self.focus_position = cf + 1
            elif cf is not None and cf >= len(self.walker) - 1:
                self.load_more()
                if cf < len(self.walker) - 1:
                    self.focus_position = cf + 1
            return None
        if key == 'page up':
            if cf is not None:
                self.focus_position = max(0, cf - 20)
            return None
        if key == 'page down':
            if cf is not None:
                self.focus_position = min(len(self.walker) - 1, cf + 20)
            return None
        if key == 'home':
            if self.walker:
                self.focus_position = 0
            return None
        if key == 'end':
            if self.walker:
                self.focus_position = len(self.walker) - 1
            return None

        return super().keypress(size, key)


# ─── 主界面 ──────────────────────────────────────────────────────────────


class DTerm:
    """Discovery 主界面控制器"""

    back_stack = []
    _key_buffer = ""
    _key_timeout = 0.3  # 300 ms 多键序列超时

    def __init__(self, forum, show_images=False):
        DTerm.self = self
        self.state = "login"
        self.forum = forum

        # ── 图片管理器 ──
        self.show_images = show_images
        self.image_manager = None
        if show_images:
            self.image_manager = ImageManager()
            if not self.image_manager.init_canvas():
                print("  警告: ueberzugpp 初始化失败，图片预览不可用")
                self.show_images = False
                self.image_manager = None

        # ── 状态机 ──
        self.state_machine = {
            'home': {
                'keys': dict(
                    list(zip(KEY_REFRESH, ['refresh'] * len(KEY_REFRESH))) +
                    list(zip(KEY_ENTER, ['viewthread'] * len(KEY_ENTER))) +
                    list(zip(KEY_BACK, ['back'] * len(KEY_BACK))) +
                    list(zip(KEY_QUIT, ['quit'] * len(KEY_QUIT))) +
                    [('j', 'vim_down'), ('k', 'vim_up'),
                     ('l', 'viewthread'), ('h', 'back'),
                     ('ctrl d', 'vim_pagedown'), ('ctrl u', 'vim_pageup')]
                ),
                'handlers': {
                    'refresh':       self.refresh,
                    'viewthread':    self.viewthread,
                    'back':          self.turn_back,
                    'quit':          self.quit,
                    'vim_down':      self.vim_down,
                    'vim_up':        self.vim_up,
                    'vim_pagedown':  self.vim_pagedown,
                    'vim_pageup':    self.vim_pageup,
                },
            },
            'post': {
                'keys': dict(
                    list(zip(KEY_BACK, ['back'] * len(KEY_BACK))) +
                    list(zip(KEY_QUIT, ['quit'] * len(KEY_QUIT))) +
                    [('j', 'vim_down'), ('k', 'vim_up'),
                     ('h', 'back'), ('l', None),
                     ('ctrl d', 'vim_pagedown'), ('ctrl u', 'vim_pageup'),
                     ('tab', 'img_next'), ('p', 'img_toggle'),
                     ('enter', 'img_original')]
                ),
                'handlers': {
                    'back':          self.turn_back,
                    'quit':          self.quit,
                    'vim_down':      self.vim_down,
                    'vim_up':        self.vim_up,
                    'vim_pagedown':  self.vim_pagedown,
                    'vim_pageup':    self.vim_pageup,
                    'img_next':      self.img_cycle_next,
                    'img_toggle':    self.img_toggle,
                    'img_original':  self.img_toggle_original,
                },
            },
        }

        # ── 启动画面 ──
        splash_text = urwid.BigText("Discovery", urwid.font.Thin6x6Font())
        splash_text = urwid.Padding(splash_text, 'center', width='clip')
        splash = urwid.Filler(splash_text, 'middle')
        self.home = urwid.Frame(splash)

        # ── 列表头 ──
        self.header = urwid.AttrMap(urwid.Columns([
            (15, urwid.Padding(urwid.Text("作者"), align='right', width='pack')),
            (1, urwid.Text('|')),
            ('weight', 1, urwid.Text("标题")),
        ], dividechars=0), 'header')

        # ── 状态栏 ──
        self.status_text = urwid.Text("")
        self.home.footer = urwid.AttrMap(self.status_text, 'footer')

        # ── 主循环 ──
        self.loop = urwid.MainLoop(
            self.home, PALETTE,
            unhandled_input=self.on_keypress,
            handle_mouse=False,
        )
        self.loop.set_alarm_in(0, self.on_start)

        # 终端大小变更检测（用于图片重排）
        self._last_term_size = None
        if self.show_images:
            self._periodic_resize_check()

        try:
            self.loop.run()
        finally:
            if self.image_manager:
                self.image_manager.cleanup()

    # ── 基础方法 ──

    def quit(self):
        raise urwid.ExitMainLoop()

    def update_status(self, status):
        self.status_text.set_text(status)
        self.loop.draw_screen()

    # ── 视图切换 ──

    def refresh(self):
        self.update_status('加载中...')
        self.thread_list = ThreadListBox(self.on_thread_page)
        self.home.body = self.thread_list
        self.home.header = self.header
        self.state = "home"
        self.update_status(
            f'共 {len(self.thread_list.threads)} 个主题 | '
            f'j/k=移动 Enter=查看 q=退出'
        )

    def viewthread(self):
        if not hasattr(self, 'thread_list') or not self.thread_list.threads:
            return

        idx = self.thread_list.focus_position
        if idx is None:
            return
        thread = self.thread_list.threads[idx]

        # 保存当前状态到回退栈
        self.back_stack.append(('home', self.thread_list, self.home.body))

        # 进入帖子视图
        self.post_list = PostListBox(thread.id, self.on_post_page)
        self.home.body = self.post_list

        header_text = urwid.Text(f"帖子: {thread.title}", wrap='clip')
        self.home.header = urwid.AttrMap(header_text, 'header')
        self.state = "post"

        status = f'{len(self.post_list.posts)} 条回复 | h/Esc=返回 q=退出'
        if self.show_images:
            status += ' Tab=下一张图 Enter=原图 p=开关图片'
        self.update_status(status)

        # 首次进入时刷新图片
        if self.show_images:
            self.image_manager._last_post_id = None
            self.loop.set_alarm_in(0.1, self._update_images)

    def turn_back(self):
        if self.back_stack:
            state, listbox, body = self.back_stack.pop()
            self.home.body = body
            self.home.header = self.header
            self.state = state
            # 清除图片
            if self.image_manager:
                self.image_manager.clear()
            if hasattr(self, 'thread_list'):
                self.update_status(
                    f'共 {len(self.thread_list.threads)} 个主题 | '
                    f'j/k=移动 Enter=查看 q=退出'
                )

    # ── 数据回调 ──

    def on_thread_page(self, title, page):
        records, pages, threads = self.forum.display(page)
        return records, pages, threads

    def on_post_page(self, tid, page, authorid):
        pages, posts = self.forum.viewthread(tid, page, authorid)
        return pages, posts

    # ── 启动 ──

    def on_start(self, loop, data):
        self.update_status(f'已登录 [{self.forum.username}]')
        self.refresh()

    # ── 图片相关 ──

    def _update_images(self, loop=None, data=None):
        """检查当前焦点帖子并刷新图片显示"""
        if not self.show_images or not self.image_manager:
            return

        if self.state == 'post' and hasattr(self, 'post_list') and self.post_list.posts:
            focus_idx = self.post_list.focus_position
            if focus_idx is not None and focus_idx < len(self.post_list.posts):
                post = self.post_list.posts[focus_idx]
                term_size = self.loop.screen.get_cols_rows()
                self.image_manager.update_display(
                    post.images, post.id, term_size,
                )
                self._refresh_image_status()

    def _refresh_image_status(self):
        """刷新状态栏的图片信息"""
        if self.state != 'post' or not hasattr(self, 'post_list'):
            return
        focus_idx = self.post_list.focus_position
        if focus_idx is None:
            return
        base = f'{focus_idx + 1}/{len(self.post_list.posts)}'
        if self.image_manager and self.image_manager.image_info:
            base += f'  {self.image_manager.image_info}'
        else:
            base += '  h/Esc=返回 q=退出'
        self.update_status(base)

    def img_cycle_next(self):
        """切换到当前帖子的下一张图片"""
        if not self.image_manager or not self.image_manager.enabled:
            return
        term_size = self.loop.screen.get_cols_rows()
        self.image_manager.cycle_next(term_size)
        self._refresh_image_status()

    def img_toggle(self):
        """开关图片预览"""
        if not self.image_manager or not self.image_manager.enabled:
            return
        enabled = self.image_manager.toggle_preview()
        if enabled:
            self.image_manager._last_post_id = None  # 强制刷新
            self._update_images()
        else:
            self._refresh_image_status()

    def img_toggle_original(self):
        """Enter: 切换缩略图/原图显示"""
        if not self.image_manager or not self.image_manager.enabled:
            return
        term_size = self.loop.screen.get_cols_rows()
        self.image_manager.toggle_original(term_size)
        self._refresh_image_status()

    def _periodic_resize_check(self, loop=None, data=None):
        """每秒检查终端尺寸变化，必要时重排图片"""
        if self.show_images and self.image_manager:
            try:
                cur = self.loop.screen.get_cols_rows()
                if cur != self._last_term_size:
                    if self._last_term_size is not None:
                        # 终端尺寸变化，重绘图片
                        self.image_manager._last_post_id = None
                        self._update_images()
                    self._last_term_size = cur
            except Exception:
                pass
        self.loop.set_alarm_in(1.0, self._periodic_resize_check)

    # ── Vim 占位 ──

    def vim_down(self):     pass
    def vim_up(self):       pass
    def vim_pagedown(self): pass
    def vim_pageup(self):   pass

    # ── 按键处理 ──

    def on_keypress(self, key):
        # ── 全局退出 ──
        if key in ('q', 'Q'):
            self.quit()
            return True

        # ── Vim 多键序列 (gg) ──
        if key == 'g':
            self._key_buffer = 'g'
            self.loop.set_alarm_in(self._key_timeout, self._clear_key_buffer)
            return True

        if self._key_buffer == 'g' and key == 'g':
            self._key_buffer = ''
            if self.state == 'home' and hasattr(self, 'thread_list'):
                self.thread_list.set_focus(0)
            elif self.state == 'post' and hasattr(self, 'post_list'):
                self.post_list.set_focus(0)
                if self.show_images:
                    self.loop.set_alarm_in(0.05, self._update_images)
            return True

        if key == 'G':
            self._key_buffer = ''
            if self.state == 'home' and hasattr(self, 'thread_list') and self.thread_list.walker:
                self.thread_list.set_focus(len(self.thread_list.walker) - 1)
                self.thread_list.load_more()
            elif self.state == 'post' and hasattr(self, 'post_list') and self.post_list.walker:
                self.post_list.set_focus(len(self.post_list.walker) - 1)
                self.post_list.load_more()
                if self.show_images:
                    self.loop.set_alarm_in(0.05, self._update_images)
            return True

        # ── Tab / p 图片快捷键（直接处理，不等状态机） ──
        if key == 'tab' and self.state == 'post' and self.show_images:
            self.img_cycle_next()
            return True

        if key == 'p' and self.state == 'post' and self.show_images:
            self.img_toggle()
            return True

        # ── 清除多键缓冲 ──
        self._clear_key_buffer()

        # ── 状态机路由 ──
        if self.state in self.state_machine:
            sm = self.state_machine[self.state]

            # j/k/ctrl d/u 交给 ListBox 自行处理，之后异步刷新图片
            if key in ('j', 'k', 'ctrl d', 'ctrl u'):
                if self.show_images and self.state == 'post':
                    self.loop.set_alarm_in(0.05, self._update_images)
                return False  # 不消费，让 ListBox 处理

            if key in sm['keys']:
                action = sm['keys'][key]
                if action and action in sm['handlers']:
                    sm['handlers'][action]()
                    if self.show_images and self.state == 'post':
                        self.loop.set_alarm_in(0.05, self._update_images)
                    return True

        return False

    def _clear_key_buffer(self, loop=None, data=None):
        self._key_buffer = ""


# ─── 入口 ────────────────────────────────────────────────────────────────


def main():
    parser = argparse.ArgumentParser(
        description='Discovery - 4d4y 论坛终端客户端',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
快捷键:
  j / k / 上 / 下          上下移动光标
  Enter / l / 右           查看帖子
  Esc / h / 左             返回上级
  gg                       跳到列表顶部
  G                        跳到列表底部
  Ctrl+d / Ctrl+u          半页上/下滚动
  r                        刷新帖子列表
  q                        退出

图片预览 (需 -p 参数):
  Tab                      下一张图片
  Enter                    切换缩略图/原图
  p                        开关图片预览

登录信息保存在 ~/.4d4y-login
""",
    )
    parser.add_argument(
        '-p', '--preview',
        action='store_true',
        help='使用 ueberzugpp 显示帖子中的图片',
    )
    args = parser.parse_args()

    print("╔═════════════════════════════════╗")
    print("║    Discovery  论坛终端客户端     ║")
    print("╚═════════════════════════════════╝")
    print()

    # 加载已保存的凭证（默认为空）
    username, password = load_credentials()

    # 首次使用时提示输入
    if not username:
        print("  首次使用，请输入登录信息")
        username, password = prompt_credentials()

    # 尝试登录（最多 3 次）
    max_attempts = 3
    forum = None

    for attempt in range(max_attempts):
        if not username:
            print("  未提供用户名，退出。")
            sys.exit(1)

        forum = Forum(username, password)
        sys.stdout.write(f"  正在登录 [{username}]... ")
        sys.stdout.flush()

        if forum.login():
            print("成功!")
            # 凭证未保存过时询问
            if not os.path.exists(LOGIN_FILE):
                save = input("  保存登录信息? [Y/n]: ").strip().lower()
                if save != 'n':
                    save_credentials(username, password)
                    print(f"  已保存到 {LOGIN_FILE}")
            break
        else:
            print("失败")
            if attempt < max_attempts - 1:
                print("  请重新输入登录信息")
                username, password = prompt_credentials()
            else:
                print("  登录失败次数过多，退出。")
                sys.exit(1)

    # 检查 ueberzugpp
    if args.preview:
        try:
            subprocess.run(['ueberzugpp', '--version'], capture_output=True, timeout=5)
        except (FileNotFoundError, subprocess.TimeoutExpired):
            print("  警告: ueberzugpp 未安装，图片预览功能不可用")
            print("  安装方法: https://github.com/ueberzug/ueberzugpp")
            args.preview = False

    try:
        DTerm(forum, show_images=args.preview)
    except KeyboardInterrupt:
        print("\n  再见!")
    except Exception as e:
        print(f"  错误: {e}")
        import traceback
        traceback.print_exc()


if __name__ == "__main__":
    main()
