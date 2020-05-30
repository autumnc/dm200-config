(provide 'modes-setting)
;;中英文混排
(use-package pangu-spacing
  :config
  (global-pangu-spacing-mode 1))
;;--------------------------------------

;;writeroom
(defun hide-all-and-focus-mode()
    (interactive)
	     (shell-command "tmux set status")
	     (writeroom-mode))
;;(add-hook 'writeroom-mode-hook (lambda () (focus-mode)))
;;--------------------------------------

(add-hook 'auto-save-hook 'auto-save-silence+)
(defun auto-save-silence+ ()
  (setq inhibit-message t)
  (run-at-time 0 nil
               (lambda ()
                 (setq inhibit-message nil))))
