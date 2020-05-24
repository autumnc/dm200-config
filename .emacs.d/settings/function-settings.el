(provide 'function-settings)
;; 关于没有选中区域,则默认为选中整行的advice
;; 默认情况下M-w复制一个区域，但是如果没有区域被选中，则复制当前行
(defadvice kill-ring-save (before slickcopy activate compile)
  (interactive
   (if mark-active (list (region-beginning) (region-end))
     (message "已选中当前行!")
     (list (line-beginning-position)
           (line-beginning-position 2)))))
;;光标在行首C-w剪切整行
(global-set-key "\C-w"
		(lambda ()
		  (interactive)
		  (if mark-active
		      (kill-region (region-beginning)
				   (region-end))
		    (progn
		      (kill-region (line-beginning-position)
				   (line-end-position))
		      (message "killed line")))))
;;--------------------------------------
