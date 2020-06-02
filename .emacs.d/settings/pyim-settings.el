(provide 'pyim-settings)
;;pyim拼音输入法设置
(use-package pyim
  :defer t
  :ensure t
  :config
  ;; 激活 basedict 拼音词库
  (use-package pyim-basedict
    :defer nil
    :ensure t
    :config (pyim-basedict-enable))

  ;; 我使用全拼
  (setq pyim-default-scheme 'quanpin)

  ;; 设置 pyim 探针设置，行首自动半角符号
  (setq-default pyim-punctuation-half-width-functions
                '(pyim-probe-punctuation-line-beginning
                  pyim-probe-punctuation-after-punctuation))

  ;; 开启拼音搜索功能
  (pyim-isearch-mode 1)

  ;; 使用 pupup-el 来绘制选词框
  (setq pyim-page-tooltip 'minibuffer)

  ;; 选词框显示5个候选词
  (setq pyim-page-length 9)

  ;;候选詞翻页
  (define-key pyim-mode-map "." 'pyim-page-next-page)
  (define-key pyim-mode-map "," 'pyim-page-previous-page)

  ;; 让 Emacs 启动时自动加载 pyim 词库
;  (add-hook 'emacs-startup-hook
;            #'(lambda () (pyim-restart-1 t)))
  :bind
  (("M-j" . pyim-convert-code-at-point)
   ("C-;" . pyim-delete-word-from-personal-buffer)))

(setq default-input-method "pyim")

;;全局切换输入法快捷键
;;输出变量到文件
(defun print-to-file (filename data)
  (interactive)
  (with-temp-file filename
    (prin1 data (current-buffer))))

;;启动默认英文
;(add-hook 'emacs-startup-hook
;	  (print-to-file "/tmp/emacs_input_status" current-input-method)
;	  (shell-command "tmux refresh-client -S"))

;;切换改变状态
(defun chinese-switch-status()
  (interactive)
  (toggle-input-method)
  (print-to-file "/tmp/emacs_input_status" current-input-method)
  (shell-command "tmux refresh-client -S"))

;(global-set-key (kbd "C-\\") 'chinese-switch-status)
(global-set-key (kbd "C-\\") 'toggle-input-method)

(setq pyim-punctuation-translate-p '(auto yes no))   ;中文使用全角标点，英文使用半角标点。
;;--------------------------------------

