(defun count-freq (xs)
  (let ((table (make-hash-table)))
    (dolist (n xs table)
      (let ((current-count (gethash n table 0)))
        (setf (gethash n table) (1+ current-count))
      ))))

(defun hash-table-values (table)
  (let ((values '()))
    (maphash (lambda (key value) (push value values)) table)
    values))

(defun find-rank (cards)
  (let ((freq-table (count-freq (coerce cards 'list))))
    (let ((sorted-freqs (sort (hash-table-values freq-table) #'<)))
      (cond
        ((equal sorted-freqs '(5)) "9")
        ((equal sorted-freqs '(1 4)) "8")
        ((equal sorted-freqs '(2 3)) "7")
        ((equal sorted-freqs '(1 1 3)) "6")
        ((equal sorted-freqs '(1 2 2)) "5")
        ((equal sorted-freqs '(1 1 1 2)) "4")
        ((equal sorted-freqs '(1 1 1 1 1)) "3")))))

(defparameter *char-table* (make-hash-table))
(setf (gethash #\A *char-table*) #\z)
(setf (gethash #\K *char-table*) #\y)
(setf (gethash #\Q *char-table*) #\x)
(setf (gethash #\J *char-table*) #\w)
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
      (concatenate 'string (find-rank cards) (normalize cards))
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
