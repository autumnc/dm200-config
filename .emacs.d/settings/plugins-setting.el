(provide 'plugins-setting)

;;session保存编辑状态
(use-package session)
(add-hook 'after-init-hook 'session-initialize)
(desktop-save-mode t)
;;--------------------------------------

;;evernote模式
(use-package evernote-mode)
;;--------------------------------------

;;插入图标字体
(use-package all-the-icons)
;;--------------------------------------

;;侧边栏文件管理
(use-package neotree
  :defer t
  :ensure t
  :custom
  (neo-smart-open t
   neo-theme 'nerd2))
;;--------------------------------------

;;笔记搜索与整理
(use-package deft
  :defer t
  :commands (deft)
  :config
  (setq deft-directory "~/blog/content-org/"
	deft-extensions '("org")
	deft-recursive t
	deft-default-extension "org"
	deft-use-filename-as-title nil
	deft-auto-save-interval 6
	deft-auto-save-silent 1
	deft-use-filter-string-for-filename t
	deft-file-naming-rules '((noslash . "-")
				 (nospace . "-")
                                 (case-fn . downcase))
	deft-text-mode 'org-mode
	deft-incremental-search nil) ;;默认用正则表达式搜索
  ;;deft菜单辅助
  (eval-after-load "deft"
    '(progn
       (define-key deft-mode-map (kbd "<next>") 'hydra-deft/body))))
;;--------------------------------------

;;w3m浏览器设置
(use-package w3m
  :defer 2
  :ensure t
  :config
  (setq w3m-use-favicon nil)
  (setq w3m-use-cookies t)
  (setq w3m-home-page "http://tibiji.com/autumnc")
  ;;change default browser for 'browse-url'  to w3m
  (setq browse-url-browser-function 'w3m-goto-url-new-session)

  ;;change w3m user-agent to android
  (setq w3m-user-agent "Mozilla/5.0 (Linux; U; Android 2.3.3; zh-tw; HTC_Pyramid Build/GRI40) AppleWebKit/533.1 (KHTML, like Gecko) Version/4.0 Mobile Safari/533.")
)
;;--------------------------------------

;;Dired 文件管理
(use-package dired
  :ensure nil
  :defer t
  :delight "Dired "
  :custom
  (dired-auto-revert-buffer t)
  (dired-dwim-target t)
  (dired-hide-details-hide-symlink-targets nil)
  (dired-listing-switches "-alh")
  (dired-ls-F-marks-symlinks nil)
  (dired-recursive-copies 'always)
  :config
  (define-key dired-mode-map (kbd "<next>") 'hydra-dired/body))
(use-package dired-subtree
  :defer t
  :bind (:map dired-mode-map
              ("TAB" . dired-subtree-cycle)
              ("SPC" . dired-subtree-toggle)))

;;--------------------------------------

;;Which-key快捷键提示
(use-package which-key
  :defer 0.2
  :delight
  :config (which-key-mode))
;;--------------------------------------

;;modeline设置最小化
(use-package smart-mode-line)
(smart-mode-line-enable)
(use-package mini-modeline
  :after smart-mode-line
  :config
  (mini-modeline-mode t))
;;--------------------------------------

;; howm
(require 'howm)
(global-set-key "\C-x,," 'howm-menu)
(setq howm-home-directory "~/blog/content-org/")
;(setq howm-keyword-file (concat howm-home-directory ".howm-keys"))
;(setq howm-file-name-format "%Y/%m/%d/%Y%m%d-%H%M%S.howm")
;(setq howm-menu-file (concat howm-home-directory "menu.txt"))
(setq howm-history-file (concat howm-home-directory ".howm-history"))
(autoload 'howm-menu "howm-mode" "Hitori Otegaqru Wiki Modoki" t)

;;color-rg
(use-package color-rg)
