(provide 'general-settings)

(fset 'yes-or-no-p 'y-or-n-p);;简化确认时的输入
;(blink-cursor-mode 0)
;(tool-bar-mode 0);;不显示工具栏
(menu-bar-mode 0);;不显示菜单栏
;(scroll-bar-mode -1);;不显示滚动条
;(set-scroll-bar-mode nil)
;;(global-linum-mode t) ;侧边显示行号
(column-number-mode t) ;状态栏显示行列信息
(show-paren-mode t) ;括号匹配高亮
(global-hl-line-mode 1) ;当前行高亮
(setq auto-save-default nil) ;不生成##文件
(setq backup-by-copying nil) ;不生成~文件
(electric-pair-mode t);自动补全括号
(setq inhibit-startup-message t);;关闭启动画面
(global-font-lock-mode t);;高亮
(setq kill-ring-max 200);;设定删除保存记录为200
(setq-default kill-whole-line t);; 在行首 C-k 时，同时删除该行。
(setq diary-file "~/.gtd/diary")
;;主题设置
(load-theme 'ir-black t)
;;断句相关
(setq sentence-end "\\([。！：；？]\\|……\\|[.?!][]\"')}]*\\($\\|[ \t]\\)\\)[ \t\n]*")
;;滚动页面
(setq scroll-step 1
          scroll-margin 3
          scroll-conservatively 10000)
;; 自动的在文件末增加一新行
(setq require-final-newline t)
;;延迟加载所有的packages
;;(setq use-package-always-defer t)
;;系统时间设为英文
(setq system-time-locale "C")
;;自动保存文件管理
(setq backup-directory-alist (quote (("." . "~/.emacs-backups"))))
;;--------------------------------------

;;编码问题
(set-language-environment "UTF-8")
(set-default-coding-systems 'utf-8)
(set-buffer-file-coding-system 'utf-8-unix)
(set-clipboard-coding-system 'utf-8-unix)
(set-file-name-coding-system 'utf-8-unix)
(set-keyboard-coding-system 'utf-8-unix)
(set-next-selection-coding-system 'utf-8-unix)
(set-selection-coding-system 'utf-8-unix)
(set-terminal-coding-system 'utf-8-unix)
(setq locale-coding-system 'utf-8)
(prefer-coding-system 'utf-8)
(require 'eaw)
(eaw-fullwidth)

;;--------------------------------------

;;快捷键
(global-set-key [f1] 'calendar) ;;F1日历与日志
(global-set-key [f2] 'undo) ;;F2撤销
(global-set-key [f3] 'kill-this-buffer) ;;F3关闭当前buffer
(global-set-key [f10] 'buffer-menu) ;;F10打开buffer清单
(global-set-key [f9] 'neotree-toggle) ;;F9打开neotree
;;改变set-mark的快捷键
(global-unset-key (kbd "C-SPC"))  
(global-set-key (kbd "M-SPC") 'set-mark-command)  
