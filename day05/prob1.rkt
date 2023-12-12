#lang racket

(require racket/string)

(struct range-mapping (to from size))

(define (compare-range-by-from r1 r2)
  (< (range-mapping-from r1) (range-mapping-from r2)))

(define (display-range-mapping r)
  (printf "Range: ~a <= [~a,~a) (+~a)\n"
          (range-mapping-to r)
          (range-mapping-from r)
          (+ (range-mapping-from r) (range-mapping-size r))
          (range-mapping-size r)))

(define (parse-range line)
  (apply range-mapping (map string->number (string-split line " ")))
)

;; https://codereview.stackexchange.com/questions/87058/splitting-a-list-in-racket
;; with evq? changed to equal?
(define (split-by lst x)
  (foldr (lambda (element next)
           (if (equal? element x)
             (cons empty next)
             (cons (cons element (first next)) (rest next))))
         (list empty) lst))

(define (not-ending-with-map? str)
  (not (string-suffix? str "map:")))

; sort is not needed in the current impl
(define (parse-and-sort-map map-lines)
  (sort (map parse-range map-lines) compare-range-by-from))

(define (try-convert-in-range seed range-mapping)
  (let ((offset (- seed (range-mapping-from range-mapping))))
    (if (and (>= offset 0) (< offset (range-mapping-size range-mapping)))
      (+ (range-mapping-to range-mapping) offset)
      -1)))

; ranges doesn't need to be sorted, I'm just being lazy
(define (convert-by-ranges sorted-ranges seed)
  (let ((converted (findf
                     (lambda (x) (not (= x -1)))
                     (map (curry try-convert-in-range seed) sorted-ranges))))
    (if converted converted seed)))

(define all-lines (string-split (port->string (current-input-port)) "\n"))

(define seeds-line (list-ref (string-split (car all-lines) ":") 1))

(define range-maps-lines 
  (split-by (filter not-ending-with-map? (drop all-lines 2)) ""))

; (for-each (lambda (lines)
    ; (display-lines (append lines (list ""))))
    ; range-maps-lines)

(define all-range-maps (map parse-and-sort-map range-maps-lines))

(define (convert-through seed)
  (foldl convert-by-ranges seed all-range-maps))

(let ((seeds (map string->number (string-split seeds-line " "))))
  (displayln (apply min (map convert-through seeds))))