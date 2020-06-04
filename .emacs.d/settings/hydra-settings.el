(provide 'hydra-settings)
;;hydra设置
;;主功能菜单
(defhydra hydra-hick (:color pink
			     :pre (shell-command "/home/dm200/bin/imswitcheng")
			     :post (shell-command "/home/dm200/bin/imswitchback")
                             :hint nil)
"
^^^^^^^^⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
_d_: deft          _c_: capture     _1_: only this      _W_: hide bar
_w_: w3m           _j_: journal     _o_: other          _f_: dired
_e_: evernote      _a_: agenda      _0_: delete         _l_: linum-mode
⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
Buf: _m_:  k_:  _]_:  _[_:  _TAB_:  ⎮ _u_:  _s_:  _n_:  _t_:  _SPC_: "  
  ("d" deft :exit t)
  ("f" dired :exit t)
  ("a" org-agenda :exit t)
  ("w" w3m :exit t)
  ("e" evernote-browsing-list-notebooks exit t)
  ("c" org-capture :exit t)
  ("j" org-journal-new-entry :exit t)
  ("m" buffer-menu :exit t)
  ("n" org-add-note :exit t)  
  ("k" kill-this-buffer)
  ("]" next-buffer)
  ("[" previous-buffer)
  ("1" delete-other-windows)
  ("0" delete-window)
  ("o" other-window)
  ("s" hydra-split/body :exit t)
  ("W" (shell-command "tmux set status"))
  ("TAB" #'(lambda ()
	     (interactive)
	     (switch-to-buffer (other-buffer (current-buffer) 1))))
  ("SPC" org-toggle-checkbox)
  ("t" org-todo exit t)
  ("l" linum-mode :toggle t)
  ("u" undo)
  ("<f11>" nil)
  ("<next>" nil)
  ("<prior>" nil)
  ("q" quit-window :color blue))

(global-set-key (kbd "<prior>") 'hydra-hick/body)

;;分割窗口
(defhydra hydra-split
  (:foreign-keys run
		 :color pink
		 :columns 2
		 :pre (shell-command "/home/dm200/bin/imswitcheng")
		 :post (shell-command "/home/dm200/bin/imswitchback")
		 :hint nil)
  "Split window"
  ("h" split-window-horizontally "Horizon")
  ("v" split-window-vertically "Verticle")
  ("b" split-window-below "Below")
  ("r" split-window-below "Right")
  ("<f11>" nil)
  ("<next>" nil)
  ("<prior>" nil)
  ("c" nil))

;;仿 vi模式
(defun hydra-vi/pre ()
  (set-cursor-color "#e52b50")
  (shell-command "/home/dm200/bin/imswitcheng"))
(defun hydra-vi/post ()
  (set-cursor-color "#ffffff"))
(global-set-key
   (kbd "<f11>")
   (defhydra hydra-vi (:pre (shell-command "/home/dm200/bin/imswitcheng")
			    :post (shell-command "/home/dm200/bin/imswitchback")
			    :foreign-keys warn
			    :color amaranth
			    :hint nil)
     "vi"
   ("j" next-line)
   ("<down>" next-line)
   ("k" previous-line)
   ("<up>" previous-line)
   ("l" forward-char)
   ("<right>" forward-char)
   ("h" backward-char)
   ("<left>" backward-char)
   ("^" (progn (beginning-of-line) (indent-according-to-mode)))
   ("<home>" beginning-of-line)
   ("$" move-end-of-line)
   ("<end>" move-end-of-line)
   ("<prior>" scroll-down "scroll down")
   ("<next>" scroll-up "scroll up")
   ("SPC" org-toggle-checkbox)
   ("t" org-todo)
   ("RET" org-todo :exit t)
   ("." forward-page)
   ("," backward-page)
   ("n" narrow-to-page :bind nil :exit t)
   ("gg" beginning-of-buffer)
   ("gt" hydra-goto-line/body :exit t)
   ("G" end-of-buffer)
   (":" (progn (call-interactively 'eval-expression)))
   ("r" recenter-top-bottom)
   ("!" shell-command "shell")
   ("[" org-backward-paragraph)
   ("]" org-forward-paragraph)
   ("dd" kill-whole-line)
   ("dw" kill-word)
   ("dp" duplicate-line-or-region :color green)
   ("u" undo)
   ("r" undo-tree-redo)
   ("w" forward-word)
   ("W" backward-word)
   ("x" delete-char)
   ("y" kill-ring-save)
   ("i" nil)
   ("<f10>" buffer-menu)
   ("<f3>" kill-current-buffer)
   ("<f11>" nil)
   ("a" nil)
   ("c" nil)))
(hydra-set-property 'hydra-vi :verbosity 1)

;;goto菜单
(defhydra hydra-goto-line (goto-map ""
                           :pre (linum-mode 1)
                           :post (linum-mode -1))
  "goto-line"
  ("g" goto-line "go")
  ("m" set-mark-command "mark" :bind nil)
  ("q" nil "quit"))

;;org菜单
(defhydra hydra-org (:foreign-keys run
				   :pre (shell-command "/home/dm200/bin/imswitcheng")
				   :post (shell-command "/home/dm200/bin/imswitchback")
				   :color red :hint nil)
  "
^^^^^^^^⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
Link: _I_: insert _O_: open _]_: next _[_: prev _S_: store _T_: display
Nav\: _j_: ↓ _k_: ↑ _n_: |↓ _p_: |↑ _c_: ↕ _C_: ⇕ _l_: → _h_: ← _J_: ⇑ _K_: ⇓  
Gtd\: _a_: _td_: _b_: SPC_: _d_: _I_: _s_: _ts_: _tg_: _ta_: _g_:
"
  ("j" outline-next-visible-heading)
  ("k" outline-previous-visible-heading)
  ("n" org-forward-heading-same-level)
  ("p" org-backward-heading-same-level)
  ("u" outline-up-heading)
  ("c" org-cycle)
  ("C" org-global-cycle)
  ("h" org-promote-subtree)
  ("l" org-demote-subtree)
  ("J" org-move-subtree-up)
  ("K" org-move-subtree-down)
  ("SPC" org-capture)
  ("d" org-deadline)
  ("td" org-todo)
  ("b" org-toggle-checkbox)
  ("I" org-insert-link)
  ("O" org-open-link-from-string)
  ("]" org-next-link)
  ("[" org-previous-link)
  ("S" org-store-link)
  ("T" org-toggle-link-display)
  ("a" org-agenda :exit t)
  ("ta" org-table-create)
  ("tg" org-tags-view)
  ("ts" org-time-stamp)
  ("g" org-goto :exit t)
  ("s" org-search-view)
  ("q" nil)
  ("<prior>" nil)
  ("<next>" nil)
  ("<f11>" nil ))

;;deft菜单
(defhydra hydra-deft
  (:foreign-keys run
		 :pre (shell-command "/home/dm200/bin/imswitcheng")
		 :post (shell-command "/home/dm200/bin/imswitchback")
		 :color pink :columns 3 :hint nil)
"Deft Menu"
  ("n" deft-new-file "New file")
  ("N" deft-new-file-named "New file named")
  ("d" deft-delete-file "Delete")
  ("R" deft-rename-file "Rename")
  ("f" deft-find-file "Find file")
  ("o" deft-open-file-other-window "Open in other window")
  ("a" deft-archive-file "Archive file")
  ("r" deft-refresh "Refresh")
  ("q" quit-window "Quit" :exit t)
  ("i" deft-toggle-incremental-search "Incremental search")
  ("s" deft-toggle-sort-method "Sort method")
  ("c" nil "Cancel")
  ("<next>" nil)
  ("<f11>" nil)
  ("<prior>" nil))

;; Hydra for org agenda (graciously taken from Spacemacs)
(defhydra hydra-org-agenda (:hint none
				  :pre (shell-command "/home/dm200/bin/imswitcheng")
				  :post (shell-command "/home/dm200/bin/imswitchback"))
  "
Org agenda (_q_uit)

^Clock^      ^Visit entry^              ^Date^             ^Other^
^-----^----  ^-----------^------------  ^----^-----------  ^-----^---------
_ci_ in      _SPC_ in other window      _ds_ schedule      _gr_ reload
_co_ out     _TAB_ & go to location     _dd_ set deadline  _._  go to today
_cq_ cancel  _RET_ & del other windows  _dt_ timestamp     _gd_ go to date
_cj_ jump    _o_   link                 _+_  do later      ^^
^^           ^^                         _-_  do earlier    ^^
^^           ^^                         ^^                 ^^
^View^          ^Filter^                 ^Headline^         ^Toggle mode^
^----^--------  ^------^---------------  ^--------^-------  ^-----------^----
_vd_ day        _ft_ by tag              _ht_ set status    _tf_ follow
_vw_ week       _fr_ refine by tag       _hk_ kill          _tl_ log
_vt_ fortnight  _fc_ by category         _hr_ refile        _ta_ archive trees
_vm_ month      _fh_ by top headline     _hA_ archive       _tA_ archive files
_vy_ year       _fx_ by regexp           _h:_ set tags      _tr_ clock report
_vn_ next span  _fd_ delete all filters  _hp_ set priority  _td_ diaries
_vp_ prev span  ^^                       ^^                 ^^
_vr_ reset      ^^                       ^^                 ^^
^^              ^^                       ^^                 ^^
"
  ;; Entry
  ("hA" org-agenda-archive-default)
  ("hk" org-agenda-kill)
  ("hp" org-agenda-priority)
  ("hr" org-agenda-refile)
  ("h:" org-agenda-set-tags)
  ("ht" org-agenda-todo)
  ;; Visit entry
  ("o"   link-hint-open-link :exit t)
  ("<tab>" org-agenda-goto :exit t)
  ("TAB" org-agenda-goto :exit t)
  ("SPC" org-agenda-show-and-scroll-up)
  ("RET" org-agenda-switch-to :exit t)
  ;; Date
  ("dt" org-agenda-date-prompt)
  ("dd" org-agenda-deadline)
  ("+" org-agenda-do-date-later)
  ("-" org-agenda-do-date-earlier)
  ("ds" org-agenda-schedule)
  ;; View
  ("vd" org-agenda-day-view)
  ("vw" org-agenda-week-view)
  ("vt" org-agenda-fortnight-view)
  ("vm" org-agenda-month-view)
  ("vy" org-agenda-year-view)
  ("vn" org-agenda-later)
  ("vp" org-agenda-earlier)
  ("vr" org-agenda-reset-view)
  ;; Toggle mode
  ("ta" org-agenda-archives-mode)
  ("tA" (org-agenda-archives-mode 'files))
  ("tr" org-agenda-clockreport-mode)
  ("tf" org-agenda-follow-mode)
  ("tl" org-agenda-log-mode)
  ("td" org-agenda-toggle-diary)
  ;; Filter
  ("fc" org-agenda-filter-by-category)
  ("fx" org-agenda-filter-by-regexp)
  ("ft" org-agenda-filter-by-tag)
  ("fr" org-agenda-filter-by-tag-refine)
  ("fh" org-agenda-filter-by-top-headline)
  ("fd" org-agenda-filter-remove-all)
  ;; Clock
  ("cq" org-agenda-clock-cancel)
  ("cj" org-agenda-clock-goto :exit t)
  ("ci" org-agenda-clock-in :exit t)
  ("co" org-agenda-clock-out)
  ;; Other
  ("q" nil :exit t)
  ("gd" org-agenda-goto-date)
  ("." org-agenda-goto-today)
  ("gr" org-agenda-redo))

;;org-mode的插入模板设置
(defhydra hydra-org-template (:color blue
				     :pre (shell-command "/home/dm200/bin/imswitcheng")
				     :post (shell-command "/home/dm200/bin/imswitchback")
				     :hint nil)
  "
_s_rc  _c_enter  _q_uote      _l_atex   _e_xample  _i_ndex:  _a_scii 
_h_tml _v_erse   _I_NCLUDE:   _L_aTeX:  _H_TML:    _A_SCII:  _m_atadata
"
  ("s" (hot-expand "<s"))
  ("e" (hot-expand "<e"))
  ("q" (hot-expand "<q"))
  ("v" (hot-expand "<v"))
  ("c" (hot-expand "<c"))
  ("l" (hot-expand "<l"))
  ("h" (hot-expand "<h"))
  ("a" (hot-expand "<a"))
  ("L" (hot-expand "<L"))
  ("i" (hot-expand "<i"))
  ("I" (hot-expand "<I"))
  ("m" (hot-expand "<m"))
  ("H" (hot-expand "<H"))
  ("A" (hot-expand "<A"))
  ("<" self-insert-command "ins")
  ("o" nil "quit"))

(defun hot-expand (str)
  "Expand org template."
  (insert str)
  (org-try-structure-completion))

;;buffer-menu
(defhydra hydra-buffer-menu (:color pink
				    :pre (shell-command "/home/dm200/bin/imswitcheng")
				    :post (shell-command "/home/dm200/bin/imswitchback")
				    :hint nil)
  "
  Mark               Unmark            Actions           Search
⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
_m_: mark          _u_: unmark        _x_: execute       _R_: re-isearch
_s_: save          _U_: unmark up     _b_: bury          _I_: isearch
_d_: delete                         _g_: refresh       _O_: multi-occur
_D_: delete up                      _t_: files only: %`Buffer-menu-files-only
_~_: modified
"
  ("m" Buffer-menu-mark nil)
  ("u" Buffer-menu-unmark nil)
  ("U" Buffer-menu-backup-unmark nil)
  ("d" Buffer-menu-delete nil)
  ("D" Buffer-menu-delete-backwards nil)
  ("s" Buffer-menu-save nil)
  ("~" Buffer-menu-not-modified nil)
  ("x" Buffer-menu-execute nil)
  ("b" Buffer-menu-bury nil)
  ("g" revert-buffer nil)
  ("t" Buffer-menu-toggle-files-only nil)
  ("O" Buffer-menu-multi-occur nil :color blue)
  ("I" Buffer-menu-isearch-buffers nil :color blue)
  ("R" Buffer-menu-isearch-buffers-regexp nil :color blue)
  ("c" nil "cancel")
  ("<next>" nil)
  ("v" Buffer-menu-select "select" :color blue)
  ("o" Buffer-menu-other-window "other-window" :color blue)
  ("q" quit-window "quit" :color blue :exit t))

(define-key Buffer-menu-mode-map (kbd "<next>") 'hydra-buffer-menu/body)

;;Dired 菜单
(defhydra hydra-dired (:hint nil
			     :pre (shell-command "/home/dm200/bin/imswitcheng")
			     :post (shell-command "/home/dm200/bin/imswitchback")
			     :color pink)
  "
_+_ mkdir  _v_iew         _m_ark       _(_ details     _i_nsert-subdir
_C_opy     _O_ view other _U_nmark all _)_ omit-mode   _$_ hide-subdir
_D_elete   _o_ pen other  _u_nmark     _l_ redisplay   _w_ kill-subdir
_R_ename   _M_ chmod      _t_oggle     _g_ revert buf  _z_ compress-file
_S_ymlink  _G_ chgrp      _E_xtension  _s_ marksort    _Z_ compress 
"
  ("\\" dired-do-ispell)
  ("(" dired-hide-details-mode)
  (")" dired-omit-mode)
  ("+" dired-create-directory)
  ("=" diredp-ediff)         ;; smart diff
  ("?" dired-summary "Summary")
  ("$" diredp-hide-subdir-nomove)
  ("A" dired-do-find-regexp "Find regexp")
  ("C" dired-do-copy)        ;; Copy all marked files
  ("D" dired-do-delete)
  ("E" dired-mark-extension)
  ("e" dired-ediff-files)
  ("F" dired-do-find-marked-files "Find Marked")
  ("G" dired-do-chgrp)
  ("g" revert-buffer)        ;; read all directories again (refresh)
  ("i" dired-maybe-insert-subdir)
  ("l" dired-do-redisplay)   ;; relist the marked or singel directory
  ("M" dired-do-chmod)
  ("m" dired-mark)
  ("O" dired-display-file)
  ("o" dired-find-file-other-window)
  ("Q" dired-do-find-regexp-and-replace "Find & Replace")
  ("R" dired-do-rename)
  ("r" dired-do-rsynch)
  ("S" dired-do-symlink)
  ("s" dired-sort-toggle-or-edit)
  ("t" dired-toggle-marks)
  ("U" dired-unmark-all-marks)
  ("u" dired-unmark)
  ("v" dired-view-file)      ;; q to exit, s to search, = gets line #
  ("w" dired-kill-subdir)
  ("Y" dired-do-relsymlink)
  ("z" diredp-compress-this-file)
  ("Z" dired-do-compress)
  ("q" nil)
  ("." nil :color blue))
