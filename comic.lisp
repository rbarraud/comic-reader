(in-package #:org.gingeralesy.web.comic-reader)

(define-page index #@"comic/" (:lquery (template "main.ctml"))
  "The front page of the site."
  (r-clip:process T))

(define-page comic #@"comic/comic(/([a-zA-Z]+))?(/([0-9]+))?"
    (:uri-groups (NIL comic-path NIL page-number)
     :lquery (template "comic.ctml"))
  "The web page for displaying a web comic page."
  (let* ((comic (or (comic :path comic-path)
                    (error 'request-not-found :message "Invalid comic requested.")))
         (page-number (when page-number
                        (parse-integer page-number :junk-allowed T)))
         (page (or (page (dm:id comic) :page-number page-number)
                   (error 'request-not-found :message "Comic page does not exist."))))
    (r-clip:process
     T
     :comic comic
     :page page)))

(define-api comic (comic-id) ()
  "API interface for getting metadata for a comic"
  (case (http-method *request*)
    (:get
     (let ((comic (or (comic :id (when comic-id
                                   (parse-integer comic-id :junk-allowed T)))
                      (error 'request-not-found :message "Comic does not exist."))))
       (api-output (comic-hash-table comic))))
    (T (wrong-method-error (http-method *request*)))))

(define-api comic/page (comic-id start end) ()
  "API interface for getting metadata for comic pages."
  (case (http-method *request*)
    (:get
     (let* ((comic (comic :id (when comic-id
                                (parse-integer comic-id :junk-allowed T))))
            (start (when start (parse-integer start :junk-allowed T)))
            (end (when end (parse-integer end :junk-allowed T)))
            (pages (make-array (1+ (- end start)) :fill-pointer 0 :element-type 'number)))
       ;; TODO: make a db.lisp function that returns all the wanted pages with a single call
       (dotimes (page-number (1+ (- end start)))
         (let ((page (page (dm:id comic) :page-number page-number)))
           (when (and page (<= (dm:field page 'publish-time) (get-universal-time)))
             (vector-push (page-hash-table page) pages))))
       (unless (< 0 (length pages))
         (error 'request-not-found :message (format NIL "Comic pages ~a to ~a do not exist." start end)))
       (api-output pages)))
    (T (wrong-method-error (http-method *request*)))))

(lquery:define-lquery-function image-metadata (node comic page)
  "Adds the attribute fields to an img element to display a comic page."
  (lquery:$ node
    (attr :src (dm:field page :image-uri)
          :title (or* (dm:field page :title)
                      (format NIL "~a - Page ~a"
                              (dm:field comic :comic-name)
                              (dm:field page :page-number)))))
  node)
