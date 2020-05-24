(provide 'hydra-settings)
;;hydra设置
;;主功能菜单
(defhydra hydra-hick (:color pink
                             :hint nil)
  "
^Function^         ^Buffer^         ^Window^            ^Mode
^^^^^^^^-----------------------------------------------------------------
_d_: deft          _m_: menu        _1_: only this      _W_: writeroom
_w_: w3m           _k_: kill        _s_: split          _f_: hide&focus 
_c_: capture       _]_: next        _o_: other          _SPC_: mini vi
_j_: journal       _[_: prev        _0_: delete         _l_: linum-mode
"
  ("d" deft :exit t)
  ("w" w3m :exit t)
  ("c" org-capture :exit t)
  ("j" org-journal-new-entry :exit t)
  ("m" buffer-menu :exit t)
  ("k" kill-this-buffer)
  ("]" next-buffer)
  ("[" previous-buffer)
  ("1" delete-other-windows)
  ("0" delete-window :exit t)
  ("o" other-window :exit t)
  ("s" hydra-split/body :exit t)
  ("W" writeroom-mode :exit t)
  ("f" hide-all-and-focus-mode :exit t)
  ("SPC" hydra-vi/body :exit t)
  ("l" linum-mode :toggle t :exit t)
  ("u" undo "undo")
  ("<f11>" nil)
  ("<next>" nil)
  ("<prior>" nil)
  ("q" quit-window "quit" :color blue :exit t))

(global-set-key (kbd "<prior>") 'hydra-hick/body)

;;分割窗口
(defhydra hydra-split
  (:foreign-keys run :color pink :columns 2 :hint nil)
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
  (set-cursor-color "#e52b50"))
(defun hydra-vi/post ()
  (set-cursor-color "#ffffff"))
(global-set-key
   (kbd "<f11>")
   (defhydra hydra-vi (:pre hydra-vi/pre
			    :post hydra-vi/post
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
   ("M-SPC" scroll-down "scroll up")
   ("SPC" scroll-up "scroll down")
   ("." forward-page)
   ("," backward-page)
   ("n" narrow-to-page :bind nil :exit t)
   ("gg" beginning-of-buffer)
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
   ("<next>" nil)
   ("RET" nil)
   ("<prior>" nil)   
   ("i" nil)
   ("<f11>" nil)
   ("a" nil)
   ("c" nil)))
(hydra-set-property 'hydra-vi :verbosity 1)

;;org菜单
(defhydra hydra-org (:foreign-keys run :color red :hint nil)
  "
^Todo^           ^Link^            ^Function^         ^Other
^^^^^^^^----------------------------------------------------------------------
_td_: todo       _li_: insert link _a_: agenda        _g_: goto  
_b_: checkbox    _lo_: open link   _ta_: table        _ls_: link store
_SPC_: capture   _ln_: next link   _tg_: tags         _s_: search
_d_: deadline    _lp_: prev link   _ts_: time stamp   _lt_: link display
----------------------------------------------------------------------
_n_: ↓ _p_: ↑ _N_: |↓ _P_: |↑ _c_: ↕_C_: ⇕ _>_: →_<_: ← _^_: ⇑ _\-_: ⇓
  "
  ("n" outline-next-visible-heading)
  ("p" outline-previous-visible-heading)
  ("N" org-forward-heading-same-level)
  ("P" org-backward-heading-same-level)
  ("u" outline-up-heading)
  ("c" org-cycle)
  ("C" org-global-cycle)
  ("<" org-promote-subtree)
  (">" org-demote-subtree)
  ("^" org-move-subtree-up)
  ("-" org-move-subtree-down)
  ("SPC" org-capture)
  ("d" org-deadline)
  ("td" org-todo)
  ("b" org-toggle-checkbox)
  ("li" org-insert-link)
  ("lo" org-open-link-from-string)
  ("ln" org-next-link)
  ("lp" org-previous-link)
  ("ls" org-store-link)
  ("lt" org-toggle-link-display)
  ("a" org-agenda)
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
  (:foreign-keys run :color pink :columns 3 :hint nil)
  "Deft Hotkeys"
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
(defhydra hydra-org-agenda (:hint none)
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
(defhydra hydra-org-template (:color blue :hint nil)
  "
_c_enter  _q_uote    _L_aTeX:
_l_atex   _e_xample  _i_ndex:
_a_scii   _v_erse    _I_NCLUDE:
_s_rc     ^ ^        _H_TML:
_h_tml    ^ ^        _A_SCII:
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
  ("H" (hot-expand "<H"))
  ("A" (hot-expand "<A"))
  ("<" self-insert-command "ins")
  ("o" nil "quit"))

(defun hot-expand (str)
  "Expand org template."
  (insert str)
  (org-try-structure-completion))

;;buffer-menu
(defhydra hydra-buffer-menu (:color pink :hint nil)
  "
  Mark               Unmark             Actions            Search
-----------------------------------------------------------------------
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
