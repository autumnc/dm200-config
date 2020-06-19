(provide 'org-settings)

;;org-mode设置
;;启动设定
(defun org-mode-my-init ()
  (define-key org-mode-map (kbd "<next>") 'hydra-org/body) ;;辅助菜单
  (define-key org-mode-map "<"
  (lambda () (interactive)
     (if (looking-back "^")
         (hydra-org-template/body)
       (self-insert-command 1))))
  (setq truncate-lines nil) ;;自动换行
  (org-bullets-mode 1)) 
(add-hook 'org-mode-hook 'org-mode-my-init)
;;--------------------------------------

;; 添加 Org-mode 文本内语法高亮
(setq org-src-fontify-natively t)
;;--------------------------------------

;;org-bullets
(use-package org-bullets)
;;--------------------------------------

;;导出为html
(setq org-html-doctype "html5")
(setq org-html-xml-declaration nil)
(setq org-html-postamble nil)
;;全局缩进
(setq org-startup-indented t)
;;todo 状态设定
(setq org-todo-keywords 
      '((sequence "TODO(t)" "INPROGRESS(i)" "WAITING(w)" "REVIEW(r)" "|" "DONE(d)" "CANCELED(c)")))
;;颜色
(setq org-todo-keyword-faces
      '(("TODO" . org-warning)
        ("INPROGRESS" . "yellow")
        ("WAITING" . "purple")
        ("REVIEW" . "orange")
        ("DONE" . "green")
        ("CANCELED" .  "red")))
;;自动更新上级任务状态
(defun org-summary-todo (n-done n-not-done)
      "Switch entry to DONE when all subentries are done, to TODO otherwise."
      (let (org-log-done org-log-states)   ; turn off logging
        (org-todo (if (= n-not-done 0) "DONE" "TODO"))))
    (add-hook 'org-after-todo-statistics-hook 'org-summary-todo)
;;--------------------------------------

;;agenda 的位置
(setq org-agenda-files (list "~/.gtd/agenda/idea.org"
                             "~/.gtd/agenda/projects.org"
                             "~/.gtd/agenda/todo.org"
			     "~/.gtd/journal/"))
;;--------------------------------------

;;org日志设定
(use-package org-journal
  :ensure t
  :defer t
  :after org
  :bind (("C-c t" . org-journal-new-entry)
         ("C-c y" . journal-file-yesterday))
  :preface
  (defun get-journal-file-yesterday ()
    "Gets filename for yesterday's journal entry."
    (let* ((yesterday (time-subtract (current-time) (days-to-time 1)))
           (daily-name (format-time-string "%Y%m%d" yesterday)))
      (expand-file-name (concat org-journal-dir daily-name))))
  
  (defun journal-file-yesterday ()
    "Creates and load a file based on yesterday's date."
    (interactive)
    (find-file (get-journal-file-yesterday)))
  :custom
  (org-journal-dir "~/.gtd/journal/")
  (org-journal-date-format "<%A, %Y %B %d>")
  (org-journal-file-format "%Y%m%d")
  :config
  (defun org-journal-file-header-func (time)
    "Custom function to create journal header."
    (concat
     (pcase org-journal-file-type
       (`daily "#+TITLE: Daily Journal\n#+STARTUP: showeverything")
       (`weekly "#+TITLE: Weekly Journal\n#+STARTUP: folded")
       (`monthly "#+TITLE: Monthly Journal\n#+STARTUP: folded")
       (`yearly "#+TITLE: Yearly Journal\n#+STARTUP: folded"))))
  (setq org-journal-file-header 'org-journal-file-header-func)
  
  (defun org-journal-save-entry-and-exit()
  "Simple convenience function.
  Saves the buffer of the current day's entry and kills the window
  Similar to org-capture like behavior"
  (interactive)
  (save-buffer)
  (kill-buffer-and-window))
(define-key org-journal-mode-map (kbd "C-x C-s") 'org-journal-save-entry-and-exit)
  )
;;--------------------------------------

;;capture模板设定
(defun org-journal-find-location ()
  ;; Open today's journal, but specify a non-nil prefix argument in order to
  ;; inhibit inserting the heading; org-capture will insert the heading.
  (org-journal-new-entry t)
  ;; Position point on the journal's top-level heading so that org-capture
  ;; will add the new entry as a child entry.
  (goto-char (point-min)))

(setq org-capture-templates
      '(("j" "Journal entry" entry (function org-journal-find-location)
	 "* %(format-time-string org-journal-time-format)%^{Title}\n%i%?")
	("i" "Idea" entry (file+headline "~/.gtd/agenda/ideas.org" "Ideas")
	 "* %?\n %i\n %a")
	("t" "Todo" entry (file+headline "~/.gtd/agenda/todo.org" "Todo soon")
	 "* TODO %? \n  %^t")))
;;--------------------------------------

;;添加文件头模板
(use-package org
  :config
  (add-to-list 'org-structure-template-alist
	       '("m" "#+TITLE: \n#+OPTIONS: ^:nil _:nil f:nil \\n:t toc:t num:t\n#+STARTUP: showeverything"))
  (add-to-list 'org-structure-template-alist
	       '("n" "#+TITLE:\n#+HUGO_BASE_DIR: ~/blog\n#+HUGO_SECTION: posts\n#+DATE:\n#+HUGO_AUTO_SET_LASTMOD: t\n#+HUGO_TAGS:笔记\n#+HUGO_CATEGORIES:笔记\n#+HUGO_DRAFT: false"))
    (add-to-list 'org-structure-template-alist
	       '("d" "#+TITLE:\n#+HUGO_BASE_DIR: ~/blog\n#+HUGO_SECTION: posts\n#+DATE:\n#+HUGO_AUTO_SET_LASTMOD: t\n#+HUGO_TAGS:摘抄\n#+HUGO_CATEGORIES:摘抄\n#+HUGO_DRAFT: false"))
    (add-to-list 'org-structure-template-alist
	       '("t" "#+TITLE:\n#+HUGO_BASE_DIR: ~/blog\n#+HUGO_SECTION: posts\n#+DATE:\n#+HUGO_AUTO_SET_LASTMOD: t\n#+HUGO_TAGS:技术\n#+HUGO_CATEGORIES:技术\n#+HUGO_DRAFT: false"))
;;Tags设定
  (setq org-tag-alist '((:startgroup . nil)
                      ("@摘抄" . nil)
                      (:grouptags . nil)
                      ("@历史" . nil)
                      ("@儒学" . nil)
                      ("@道学" . nil)
                      ("@佛学" . nil)
                      ("@诗歌" . nil)
                      ("@文学" . nil)
                      ("@制度" . nil)
                      ("@文化" . nil)
                      (:endgroup . nil)))
  )
;;--------------------------------------

;;博客设置
(use-package ox-hugo
  :after ox
  :config
;  (org-hugo-auto-export-mode))
)

;; howm
(add-hook 'org-mode-hook 'howm-mode)
(add-to-list 'auto-mode-alist '("\\.howm$" . org-mode))
(add-to-list 'auto-mode-alist '("\\.txt$" . org-mode))
(setq howm-view-title-header "*") 
(global-unset-key (kbd "C-x ,"))
(setq howm-prefix (kbd "C-x ,"))
(eval-after-load "howm-mode"
  '(progn
    (define-key howm-mode-map (kbd "C-c C-c") nil)))
;(setq howm-use-color nil)

