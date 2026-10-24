extends RefCounted

class_name SourceReference

var language: String
var book: String
var title: String
var source: String
var content_type: String

func _init(language: String, book: String, title: String, source: String, content_type: String):
	self.language = language
	self.book = book
	self.title = title
	self.source = source
	self.content_type = content_type
