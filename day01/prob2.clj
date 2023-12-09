(require '[clojure.string :as string])

(def number-map
  (merge
    (zipmap ["one" "two" "three" "four" "five" "six" "seven" "eight" "nine"]
            (iterate inc 1)) 
    (into {} (map #(vector (str %) %) (range 1 10)))
   ))

(defn match-at-start [s [name digit]]
  (if (string/starts-with? s name)
    digit
    nil))

(defn match-at-end [s [name digit]]
  (if (string/ends-with? s name)
    digit
    nil))

(defn try-match-any-digit [s matcher]
  (->> (map (partial matcher s) number-map)
       (filter some?)
       first))

(defn first-digit [s]
  (loop [remaining s]
    (if (string/blank? remaining)
      nil
      (if-let [found (try-match-any-digit remaining match-at-start)]
        found
        (recur (subs remaining 1))
        ))))

(defn last-digit [s]
  (loop [remaining s]
    (if (string/blank? remaining)
      nil
      (if-let [found (try-match-any-digit remaining match-at-end)]
        found
        (recur (subs remaining 0 (dec (.length remaining))))
        ))))

(defn get-calibration-value [s]
    (+ (* 10 (first-digit s)) (last-digit s)))

; the main
(println
 (->> (line-seq (java.io.BufferedReader. *in*))
      (map get-calibration-value)
      (apply +)
 ))
