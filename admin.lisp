(in-package #:org.gingeralesy.web.comic-reader)

(admin:define-panel comics comic-reader (:access (perm author)
                                         :icon "comments-o"
                                         :tooltip "Manage your comics."
                                         :lquery (template "admin-comic.ctml"))
  (let* ((comic-id (int-get-var "comic"))
         (comic (when comic-id (comic :id comic-id)))
         (pages (when comic (pages (dm:field comic '_id) :up-to-time NIL)))
         (author (if (auth:current) (user:username (auth:current))
                     (error 'api-auth-error :message "Missing user!")))
         (comics (comics (user:username (auth:current)))))
    (when (and comic (not (string= author (dm:field comic 'author))))
      (error 'api-auth-error :message "You may only manage your own comics."))
    (with-actions (error info)
        ((:save
          (let ((comic-path (post-var "comic-path"))
                (comic-name (post-var "comic-name"))
                (cover-uri (or* (post-var "cover-uri")))
                (description (or* (post-var "description")))
                (is-default (when (or* (post-var "is-default"))
                              (string= "true" (ratify:perform-test :boolean (post-var "is-default"))))))
            (unless (cl-ppcre:scan "^[\\w-_]+$" comic-path)
              (error 'api-argument-invalid :message "Invalid comic URL path."))
            (unless comic-name (error 'api-argument-missing :message "Comic name not provided!"))
            (when (or* cover-uri) (ratify:perform-test :url cover-uri))
            (set-comic comic-path comic-name (user:username author)
                       cover-uri description :is-default is-default))))
      (r-clip:process
       T :error error :info info
         :comics comics
         :comic comic
         :pages pages))))

(admin:define-panel comic-pages comic-reader (:access (perm author)
                                              :icon "picture-o"
                                              :title "Comic Pages"
                                              :tooltip "Manage a specific page of a comic."
                                              :lquery (template "admin-comic-page.ctml"))
  (let* ((comic-id (int-get-var "comic"))
         (page-num (int-get-var "page"))
         (comic (when comic-id (comic :id comic-id)))
         (pages (when comic (pages (dm:field comic '_id) :up-to-time NIL)))
         (page (when page-num (page (dm:field comic '_id) :page-number page-num :up-to-time NIL)))
         (author (if (auth:current) (user:username (auth:current))
                     (error 'api-auth-error :message "Missing user!"))))
    (when (and comic (not (string= author (dm:field comic 'author))))
      (error 'api-auth-error :message "You may only manage your own comics."))
    (with-actions (error info)
        ((:save
          (let ((comic-id (int-post-var "comic-id"))
                (page-number (int-post-var "page-number"))
                (image-uri (or* (post-var "image-uri")))
                (thumb-uri (or* (post-var "thumb-uri")))
                (title (or* (post-var "title")))
                (publish-time (int-post-var "publish-time"))
                (tags (or* (post-var "tags")))
                (commentary (or* (post-var "commentary")))
                (transcript (or* (post-var "transcript"))))
            (unless (comic :id comic-id)
              (error 'api-argument-invalid :message "Invalid comic."))
            (unless page-number
              (error 'api-argument-missing :message "Page number is not defined."))
            (if image-uri
                (ratify:perform-test :url image-uri)
                (error 'api-argument-missing :message "Page image is not defined."))
            (set-page comic-id page-number image-uri
                      :title title :commentary commentary
                      :publish-time publish-time :tags tags
                      :transcript transcript :thumb-uri thumb-uri))))
      (r-clip:process
       T :comics (comics (user:username (auth:current)))
         :comic comic
         :pages pages
         :page page))))

(defun int-get-var (var-name)
  (when (and var-name (or* (get-var var-name)))
    (parse-integer (get-var var-name) :junk-allowed T)))

(defun int-post-var (var-name)
  (when (and var-name (or* (post-var var-name)))
    (parse-integer (post-var var-name) :junk-allowed T)))
