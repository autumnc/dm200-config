(package-initialize)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(all-the-icons-ibuffer-mode t)
 '(custom-safe-themes
   (quote
    ("60940e1f2fa3f4e61e7a7ed9bab9c22676aa25f927d5915c8f0fa3a8bf529821" "3c83b3676d796422704082049fc38b6966bcad960f896669dfc21a7a37a748fa" "00445e6f15d31e9afaa23ed0d765850e9cd5e929be5e8e63b114a3346236c44c" "c433c87bd4b64b8ba9890e8ed64597ea0f8eb0396f4c9a9e01bd20a04d15d358" "51ec7bfa54adf5fff5d466248ea6431097f5a18224788d0bd7eb1257a4f7b773" "7f1d414afda803f3244c6fb4c2c64bea44dac040ed3731ec9d75275b9e831fe5" "2809bcb77ad21312897b541134981282dc455ccd7c14d74cc333b6e549b824f3" "13a8eaddb003fd0d561096e11e1a91b029d3c9d64554f8e897b2513dbf14b277" "4780d7ce6e5491e2c1190082f7fe0f812707fc77455616ab6f8b38e796cbffa9" "af1ad7ddaafd6a4018186f85e89bb5d79612773c1c3e08f48d903072eedb6f6e" default)))
 '(dired-auto-revert-buffer t)
 '(dired-dwim-target t)
 '(dired-hide-details-hide-symlink-targets nil)
 '(dired-listing-switches "-alh")
 '(dired-ls-F-marks-symlinks nil)
 '(dired-recursive-copies (quote always))
 '(evernote-developer-token
   "S=s65:U=e9b8ad:E=172b37f864c:C=1728f72ffd0:P=1cd:A=en-devtoken:V=2:H=fde460ba85c843c5e351d3fa857e3641")
 '(evernote-username "yangwenzu")
 '(howm-directory "~/blog/content-org/")
 '(neo-smart-open t t)
 '(org-journal-date-format "<%A, %Y %B %d>" t)
 '(org-journal-dir "~/.gtd/journal/" t)
 '(org-journal-file-format "%Y%m%d" t)
 '(package-archives
   (quote
    (("melpa" . "http://elpa.emacs-china.org/melpa/")
     ("gnu" . "https://elpa.emacs-china.org/gnu/"))))
 '(package-selected-packages
   (quote
    (howm ox-hugo mini-modeline smart-mode-line-atom-one-dark-theme smart-mode-line all-the-icons-ibuffer org-bullets dired-subtree which-key all-the-icons markdown-mode multi-term session real-auto-save-mode w3m org-journal rainbow-delimiters rainbow-mode posframe htmlize hydra writeroom-mode ir-black-theme neotree deft pangu-spacing pyim use-package diminish)))
 '(session-use-package t nil (session)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

(add-to-list 'load-path "~/.emacs.d/settings")
;;--------------------------------------

(setq gc-cons-threshold (* 50 1024 1024))

;;加载通用设置
(require 'general-settings)
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
;(require 'pyim-settings)
;;加载hydra的设置
(require 'hydra-settings)

(setq gc-cons-threshold (* 2 1000 1000))
