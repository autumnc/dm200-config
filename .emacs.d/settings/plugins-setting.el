(provide 'plugins-setting)

;;--------------------------------------
(use-package evernote-mode)

(use-package neotree
  :defer t
  :ensure t
  :custom
  (neo-smart-open t
   neo-theme 'nerd2))
;;--------------------------------------

(use-package deft
  :defer t
  :commands (deft)
  :config
  (setq deft-directory "~/orgmode-blog/src"
	deft-extensions '("md" "org")
	deft-recursive t
	deft-default-extension "org"
	deft-use-filename-as-title nil
	deft-auto-save-interval 4
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
