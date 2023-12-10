(defun count-freq (cards)
  (let ((table (make-hash-table)))
    (dolist (card cards table)
      (let ((current-count (gethash card table 0)))
        (setf (gethash card table) (1+ current-count))
      ))))

(defun hash-table-values (table)
  (let ((values '()))
    (maphash (lambda (key value) (push value values)) table)
    values))

(defun count-freq-with-jokers (cards)
  (let ((freq-table (count-freq (coerce cards 'list))))
    (let ((j-count (gethash #\J freq-table 0))
          (dummy (remhash #\J freq-table))
          (freqs-no-j-desc (sort (hash-table-values freq-table) #'>)))
      (let ((non-nil-freqs (if freqs-no-j-desc freqs-no-j-desc '(0))))
        (cons (+ j-count (car non-nil-freqs)) (cdr non-nil-freqs))))))

(defun find-rank-with-joker (cards)
  (let ((sorted-freqs (count-freq-with-jokers cards)))
    ;; unlike problem #1, freqs are ordered desc here
    (cond
      ((equal sorted-freqs '(5)) "9")
      ((equal sorted-freqs '(4 1)) "8")
      ((equal sorted-freqs '(3 2)) "7")
      ((equal sorted-freqs '(3 1 1)) "6")
      ((equal sorted-freqs '(2 2 1)) "5")
      ((equal sorted-freqs '(2 1 1 1)) "4")
      ((equal sorted-freqs '(1 1 1 1 1)) "3"))))

(defparameter *char-table* (make-hash-table))
(setf (gethash #\A *char-table*) #\z)
(setf (gethash #\K *char-table*) #\y)
(setf (gethash #\Q *char-table*) #\x)
;;; for problem #2, J is now the weakest
(setf (gethash #\J *char-table*) #\0)
(setf (gethash #\T *char-table*) #\v)

(defun replace-chars (str char-table)
  (with-output-to-string (out)
    (loop for char across str
          do (let ((replacement (gethash char char-table char)))
               (write-char replacement out)))))

;;; replace A,K,Q,J,T for simpler #'string-lessp comparison
(defun normalize (cards)
    (replace-chars cards *char-table*))

;;; (ranked normalized card, bid)
(defun parse-hand (hand)
  (let ((cards (subseq hand 0 5))
        (bid (parse-integer (subseq hand 6))))
    (list
      (concatenate 'string (find-rank-with-joker cards) (normalize cards))
      bid)))

(defun read-lines ()
  (loop for line = (read-line *standard-input* nil)
        while line
        collect (parse-hand line)))

(defun sort-by-card (list-of-tuples)
  (sort list-of-tuples
        #'(lambda (a b) (string< (first a) (first b)))))

(print
  (reduce #'+
    (loop
      for rank from 1
      for card-and-bid in (sort-by-card (read-lines))
      collect (* rank (nth 1 card-and-bid)))))
