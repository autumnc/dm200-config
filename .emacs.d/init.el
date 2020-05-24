(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("4780d7ce6e5491e2c1190082f7fe0f812707fc77455616ab6f8b38e796cbffa9" "af1ad7ddaafd6a4018186f85e89bb5d79612773c1c3e08f48d903072eedb6f6e" default)))
 '(org-journal-date-format "<%A, %Y %B %d>" t)
 '(org-journal-dir "~/orgmode-blog/src/journal/" t)
 '(package-archives
   (quote
    (("melpa" . "http://elpa.emacs-china.org/melpa/")
     ("gnu" . "https://elpa.emacs-china.org/gnu/"))))
 '(package-selected-packages
   (quote
    (real-auto-save-mode w3m org-journal rainbow-delimiters rainbow-mode posframe htmlize hydra focus writeroom-mode ir-black-theme neotree deft pangu-spacing pyim use-package diminish))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
(package-initialize)
(add-to-list 'load-path "~/.emacs.d/settings")
;;--------------------------------------
(setq gc-cons-threshold (* 50 1000 1000))
;;加载通用设置
(require 'general-settings)
;;自动保存设置
(require 'auto-save)
(auto-save-enable)
(setq auto-save-slient t)
(setq auto-save-idle 2)
;;加载功能设定
(require 'function-settings)
;;加载模式设定
(require 'modes-setting)
;;加载插件设定
(require 'plugins-setting)
;;加载rainbow颜色设定
(require 'rainbow-settings)
;;加载org-mode设定
(require 'org-settings)
;;加载输入法设置
(require 'pyim-settings)
;;加载hydra的设置
(require 'hydra-settings)

(setq gc-cons-threshold (* 8192 8192))
