extends Node

## This is a service that provides access to the scripture data.
## It can fetch cross-references, verses, and books, as well as 
## other related info.
## Interacts with models to get data from the database and is 
## used by the controllers to provide data to the views.

signal verses_searched(verses:Array)
signal verse_cross_references_searched(verses:Array)
signal books_installed

var translations = {}
var books = {}

func _ready():
	reload_data()
	books_installed.connect(reload_data)

func reload_data():
	load_translations()
	load_books()
	print("Scripture service data reloaded.")

func load_translations():
	translations.clear()
	var translation_model = BibleTranslationModel.new()
	var all_translations = translation_model.get_all_translations()
	for t in all_translations:
		translations[t["id"]] = t

func load_books():
	books.clear()
	var translation_model = BibleTranslationModel.new()
	var all_translations = translation_model.get_all_translations()
	for t in all_translations:
		var book_model = BookModel.new(t["translation_abbr"])
		var all_books = book_model.get_all_books()
		for b in all_books:
			b["translation"] = t["translation_abbr"]
			if t["id"] not in books:
				books[t["id"]] = {}
			books[t["id"]][b["id"]] = b


## Gets all books from a translation
func get_all_book_names_from_translation(translation: String) -> Array:
	var book_model = BookModel.new(translation)
	var all_books = book_model.get_all_books()
	var result = []
	for b in all_books:
		result.append(b["book_name"])
	return result

## Gets a dictionary of translations with books and chapters and verses.
## Example of how the function returns the dictionary:
## {
##   "KJV": {
##     "Genesis": {
##       1: {
##         1: {
##           "verse_id": 1,
##           "book_id": 1,
##           "chapter": 1,
##           "verse": 1,
##           "text": "In the beginning God created the heaven and the earth.",
##           "book_name": "Genesis",
##           "translation_id": 1,
##           "translation_abbr": "KJV",
##           "title": "Kjv",
##           "license": "Public Domain"
##         },
##         2: {
##			  ...
##         },
##         }
##       }
##     }
##   }
## }
##
## To access a specific verse, you can use the following code:
## var dictionary = get_translations_as_book_chapter_verse_dictionary(["KJV"])
## var verse = dictionary["KJV"]["Genesis"][1][1]
## print(verse["text"])  # Output: In the beginning God created the heaven and the earth.
func get_versions_as_book_chapter_verse_dictionary(translations:Array) -> Dictionary:
	var result:Dictionary = {}
	for translation in translations:
		var book_model = BookModel.new(translation)
		var all_books = book_model.get_all_books()
		result[translation] = {}
		for b in all_books:
			result[translation][b["book_name"]] = {}
			var verse_model = VerseModel.new(translation)
			var verses = verse_model.get_verses(b["book_name"])
			for v in verses:
				var chapter = v["chapter"]
				var verse = v["verse"]
				if chapter not in result[translation][b["book_name"]]:
					result[translation][b["book_name"]][chapter] = {}
				result[translation][b["book_name"]][chapter][verse] = v
	return result

## This works specifically with get_versions_as_book_chapter_verse_dictionary.
## Initialize the dictionary variable with get_versions_as_book_chapter_verse_dictionary(translations:Array)
## and then pass the dictionary to this function to get a specific verse.
## This function was made primarily for large-scale exporters to avoid repeated 
## queries to the database.
func get_verse_from_version_dictionary(dictionary:Dictionary, translation:String, book:String, chapter:int, verse:int) -> Dictionary:

	if dictionary.has(translation) and dictionary[translation].has(book) and dictionary[translation][book].has(chapter) and dictionary[translation][book][chapter].has(verse):
		return dictionary[translation][book][chapter][verse]
	return {}

## Gets a single verse, one entry in an array.
func get_verse(translation: String, book: String, chapter: int, verse: int, meta:Dictionary = {}) -> Array:
	
	var verse_model: VerseModel = VerseModel.new(translation)
	
	var book_model: BookModel = BookModel.new(translation)
	book_model.get_book_by_name(book)
	var book_id: int = book_model.id
	
	var verse_data: Dictionary = verse_model.get_verse(book_id, chapter, verse)
	var translation_data: Dictionary = get_translation(translation)
	if verse_data.is_empty():
		return []
	return [{
		"verse_id": verse_data["verse_id"],
		"book_id": verse_data["book_id"],
		"chapter": verse_data["chapter"],
		"verse": verse_data["verse"],
		"text": verse_data["text"],
		"book_name": book_model.book_name,
		"translation_id": verse_data["translation_id"],
		"translation_abbr": translation_data["translation_abbr"],
		"title": translation_data["title"],
		"license": translation_data["license"],
		"meta": meta,
	}]


## Get verses by book, chapter, or specific verse
func get_verses(translation: String, book: String, chapter: int = -1, verse: int = -1) -> Array:
	var verse_model: VerseModel = VerseModel.new(translation)
	var verses: Array = verse_model.get_verses(book, chapter, verse)
	var result: Array = []
	for v in verses:
		result.append({
			"verse_id": v["verse_id"],
			"verse_hash": v["verse_hash"],
			"book_id": v["book_id"],
			"chapter": v["chapter"],
			"verse": v["verse"],
			"text": v["text"],
			"book_name": v["book_name"],
			"translation_id": v["translation_id"],
			"translation_abbr": v["translation_abbr"],
			"title": v["title"],
			"license": v["license"]
		})
	return result

## Get verses by range
func get_verses_by_range(translation: String, start_book: String, start_chapter: int, start_verse: int, end_book: String, end_chapter: int, end_verse: int) -> Array:
	var verse_model = VerseModel.new(translation)
	var verses = verse_model.get_verses_by_range(start_book, start_chapter, start_verse, end_book, end_chapter, end_verse)
	var result = []
	for v in verses:
		result.append(v)
	return result

## Get cross references for a verse
func get_cross_references_for_verse(translation: String, book: String, chapter: int, verse: int) -> Array:
	var cross_reference_model = CrossReferenceModel.new(translation)
	var cross_references = cross_reference_model.get_cross_references_for_verse(book, chapter, verse)
	
	var result = []
	for cr in cross_references:
		result.append(cr)
	return result

## Get all cross references for all verses
func get_all_cross_references(translation: String) -> Array:
	var verse_model: VerseModel = VerseModel.new(translation)
	var all_verses: Array = verse_model.get_all_verses()
	var result: Array = []
	
	for verse in all_verses:
		var cross_references = get_cross_references_for_verse(
			translation, 
			verse["book_name"], 
			verse["chapter"], 
			verse["verse"]
		)
		for cr in cross_references:
			result.append(cr)
	
	return result

func get_all_cross_references_simple() -> Array:
	var cross_reference_model = CrossReferenceModel.new("scrollmapper")
	return cross_reference_model.get_all_cross_references()

## Saves a cross reference to database. 
func save_cross_reference(from_book: String, from_chapter: int, from_verse: int, to_book: String, to_chapter_start: int, to_chapter_end: int, to_verse_start: int, to_verse_end: int, votes: int, user_added: bool) -> void:
	var cross_reference_model = CrossReferenceModel.new("scrollmapper")
	if cross_reference_model.cross_reference_exists(from_book, from_chapter, from_verse, to_book, to_chapter_start, to_chapter_end, to_verse_start, to_verse_end):
		return
	cross_reference_model.from_book = from_book
	cross_reference_model.from_chapter = from_chapter
	cross_reference_model.from_verse = from_verse
	cross_reference_model.to_book = to_book
	cross_reference_model.to_chapter_start = to_chapter_start
	cross_reference_model.to_chapter_end = to_chapter_end
	cross_reference_model.to_verse_start = to_verse_start
	cross_reference_model.to_verse_end = to_verse_end
	cross_reference_model.votes = votes
	cross_reference_model.user_added = user_added
	cross_reference_model.save()

## Requests a cross  list.
func request_cross_references(translation: String, book: String, chapter: int, verse: int) -> void:
	var cross_references = get_cross_references_for_verse(translation, book, chapter, verse)
	propagate_cross_reference_search(translation, cross_references)

## Get information about a book
func get_book(translation: String, book_name: String) -> Dictionary:
	var book_model = BookModel.new(translation)
	book_model.get_book_by_name(book_name)
	return {
		"id": book_model.id,
		"book_name": book_model.book_name,
		"translation": book_model.translation
	}

## Get all chapter numbers in a book
func get_all_chapter_numbers_in_book(translation: String, book_name: String) -> Dictionary:
	var verse_model = VerseModel.new(translation)
	var chapters = verse_model.get_all_chapter_numbers(book_name)
	
	var results:Dictionary = {
		"chapters": []
	}
	for c in chapters:
		results["chapters"].append(c["chapter"])
	return results	

## Get all verse numbers in a chapter
func get_all_verse_numbers_in_chapter(translation: String, book_name: String, chapter: int) -> Dictionary:
	var verse_model = VerseModel.new(translation)
	var verses = verse_model.get_all_verse_numbers(book_name, chapter)
	
	var results:Dictionary = {
		"verses": []
	}
	for v in verses:
		results["verses"].append(v["verse"])
	return results

## Get all books for a specific translation
func get_all_books(translation: String) -> Array:
	var book_model = BookModel.new(translation)
	var all_books = book_model.get_all_books()
	var result = []
	for b in all_books:
		result.append({
			"id": b["id"],
			"book_name": b["book_name"],
			"translation": translation
		})
	return result

## Get information about a book by its ID
func get_book_by_id(translation_id:int, book_id: int) -> Dictionary:
	if books.has(translation_id):
		if books[translation_id].has(book_id):
			return books[translation_id][book_id]
	return {}

## Get information about a translation
func get_translation(translation_abbr: String) -> Dictionary:
	var translation_model = BibleTranslationModel.new()
	var translation_data = translation_model.get_translation(translation_abbr)
	if translation_data.is_empty():
		return {}
	return {
		"id": translation_data["id"],
		"translation_abbr": translation_data["translation_abbr"],
		"title": translation_data["title"],
		"license": translation_data["license"]
	}

## Get all translations
func get_all_translations() -> Array:
	var translation_model = BibleTranslationModel.new()
	var all_translations = translation_model.get_all_translations()
	var result = []
	for t in all_translations:
		result.append({
			"id": t["id"],
			"translation_abbr": t["translation_abbr"],
			"title": t["title"],
			"license": t["license"]
		})
	return result

## Get information about a translation by its ID
func get_translation_by_id(translation_id: int) -> Dictionary:
	if translation_id in translations:
		return translations[translation_id]
	return {}

## Initiate a text search based on the provided criteria.
## This function searches for verses in the scripture based on the given parameters.
## It supports different search scopes and translations.
##
## @param scope: The scope of the search, which determines the range of scriptures to search within.
##               It can be one of the following:
##               - Types.SearchScope.ALL_SCRIPTURE: Search in all scriptures.
##               - Types.SearchScope.COMMON_CANNONICAL: Search in common canonical scriptures.
##               - Types.SearchScope.EXTRA_CANNONICAL: Search in extra canonical scriptures.
## @param translation: The translation of the scripture to search in.
## @param text: The text to search for within the scriptures.
## @param book: (Optional) The specific book to search within. Default is an empty string, which means all books.
## @param chapter: (Optional) The specific chapter to search within. Default is -1, which means all chapters.
## @param meta: (Optional) Additional metadata for the search. Default is an empty dictionary.
##
## @return: void
func initiate_text_search(scope: Types.SearchScope, translation: String = "", text: String = "", book: String = "", chapter: int = -1, meta: Dictionary = {}) -> void:
	var verse_model = VerseModel.new(translation)
	var verse_model_scrollmapper = VerseModel.new("scrollmapper")
	var verses = []
	match scope:
		Types.SearchScope.ALL_SCRIPTURE:
			if translation != "scrollmapper": # Or you will get two results from scrollmapper translation.
				var verse_set_1 = verse_model.search_text(text, book, chapter)
				for v in verse_set_1:
					verses.append(v)
			var verse_set_2 = verse_model_scrollmapper.search_text(text, book, chapter)
			for v in verse_set_2:
				verses.append(v)
		Types.SearchScope.COMMON_CANNONICAL:
			verses = verse_model.search_text(text, book, chapter)
		Types.SearchScope.EXTRA_CANNONICAL:
			verses = verse_model_scrollmapper.search_text(text, book, chapter)
		_:
			verses = verse_model.search_text(text, book, chapter)
	propogate_search(translation, verses, meta)

## Initiate a search based on an array of verse hashes.
## This function searches for verses in the scripture based on the given hashes.
## It supports different search scopes and translations.
##
## @param scope: The scope of the search, which determines the range of scriptures to search within.
##               It can be one of the following:
##               - Types.SearchScope.ALL_SCRIPTURE: Search in all scriptures.
##               - Types.SearchScope.COMMON_CANNONICAL: Search in common canonical scriptures.
##               - Types.SearchScope.EXTRA_CANNONICAL: Search in extra canonical scriptures.
## @param translation: The translation of the scripture to search in.
## @param verse_hashes: The array of verse hashes to search for within the scriptures.
## @param meta: (Optional) Additional metadata for the search. Default is an empty dictionary.
##
## @return: void
func initiate_hash_based_search(scope: Types.SearchScope, translation: String = "", verse_hashes: Array = [], meta: Dictionary = {}) -> void:
	var verse_model = VerseModel.new(translation)
	var verse_model_scrollmapper = VerseModel.new("scrollmapper")
	var verses = []
	match scope:
		Types.SearchScope.ALL_SCRIPTURE:
			if translation != "scrollmapper": # Or you will get two results from scrollmapper translation.
				var verse_set_1 = verse_model.get_verses_by_verse_hashes(verse_hashes)
				for v in verse_set_1:
					verses.append(v)
			var verse_set_2 = verse_model_scrollmapper.get_verses_by_verse_hashes(verse_hashes)
			for v in verse_set_2:
				verses.append(v)
		Types.SearchScope.COMMON_CANNONICAL:
			verses = verse_model.get_verses_by_verse_hashes(verse_hashes)
		Types.SearchScope.EXTRA_CANNONICAL:
			verses = verse_model_scrollmapper.get_verses_by_verse_hashes(verse_hashes)
		_:
			verses = verse_model.get_verses_by_verse_hashes(verse_hashes)
	propogate_search(translation, verses, meta)

## Initiates a search for a single verse in a specified translation and propagates the search results.
func initiate_verse_search(translation: String = "", book: String = "", chapter: int = -1, verse: int = -1, meta:Dictionary = {}):
	var verses = get_verse(translation, book, chapter, verse)
	propogate_search(translation, verses, meta)

## Initiates a search for a list of verses in a specified translation and propagates the search results.
func initiate_id_search(translation:String, verse_ids:Array[int], meta={}):
	var verse_model:VerseModel = VerseModel.new(translation)
	var verses = verse_model.get_verses_by_ids(verse_ids)
	propogate_search(translation, verses, meta)


## Initiates a search for a range of verses in a specified translation and propagates the search results.
##
## @param translation: The translation of the Bible to search in.
## @param start_book: The name of the book where the search starts.
## @param start_chapter: The chapter number where the search starts.
## @param start_verse: The verse number where the search starts.
## @param end_book: The name of the book where the search ends.
## @param end_chapter: The chapter number where the search ends.
## @param end_verse: The verse number where the search ends.
## @param meta: Optional metadata dictionary to include with the search.
func initiate_range_search(translation: String = "", start_book: String = "", start_chapter: int = -1, start_verse: int = -1, end_book: String = "", end_chapter: int = -1, end_verse: int = -1, meta:Dictionary = {}):
	var verses = get_verses_by_range(translation, start_book, start_chapter, start_verse, end_book, end_chapter, end_verse)
	propogate_search(translation, verses, meta)

## This *important* function handles search propagation to subscribed objects. It converts the array of verse results 
## from the database into a JSON string formatted for the API. This JSON string is then emitted via a signal 
## to be received by the subscribed objects.
func propogate_search(translation_abbr:String, verse_results:Array, meta:Dictionary={}):
	if verse_results.is_empty():
		verses_searched.emit([])
		return
	var results:Array = []
	for verse_result in verse_results:
		verse_result["translation"] = get_translation_by_id(verse_result["translation_id"])
		if books.has(verse_result["translation_id"]):
			verse_result["book"] = get_book_by_id(verse_result["translation_id"], verse_result["book_id"])
		results.append(verse_result)
	verses_searched.emit(apply_meta(results, meta))

## Derived from propagate_search, this tailors verse output to cross-reference data.
func propagate_cross_reference_search(translation_abbr:String, verse_results:Array, meta:Dictionary={}):
	
	if verse_results.is_empty():
		verse_cross_references_searched.emit([])
		return
	var results:Array = []
	for verse_result in verse_results:	
		verse_result["translation"] = get_translation_by_id(verse_result["translation_id"])
		if books.has(verse_result["translation_id"]):
			verse_result["book"] = get_book_by_id(verse_result["translation_id"], verse_result["book_id"])
		verse_result['meta'] = meta
		results.append(verse_result)
	verse_cross_references_searched.emit(apply_meta(results, meta))

func emit_books_installed():
	books_installed.emit()

#region helper functions
func apply_meta(search_results:Array, meta:Dictionary) -> Array:
	if meta.is_empty():
		return search_results
	var i:int = 0
	for verse in search_results:
		var verse_id:int = verse["verse_id"]
		if meta.has(verse_id):
			search_results[i]["meta"]= meta[verse_id]
		i += 1
	return search_results

## This function takes a verse and a meta dictionary and creates a key based on the verse id,
## then places the meta in that key.
##
## Meta will take on various forms depending on which workstation uses it.
##
## Example:
##
## { 1814: { "work_space": "vx" } }
##
## Parameters:
## - verse: The verse object containing the verse_id.
## - meta: The dictionary containing metadata to be applied to the verse.
static func apply_verse_meta(verse:Verse, meta:Dictionary) -> Dictionary:
	return {verse.verse_id: meta}

## Will merge verse meta. Used in other functions directly after apply_verse_meta.
##
## When a process is creating a collection of verses to push to a workstation, they may have special directives attached to them (in the meta). 
## As verses are looped through, the meta_dictionary must be updated. That is what this function is responsible for.
##
## Parameters:
## - meta: The main meta dictionary.
## - verse_meta: The verse being appended to the dictionary.
static func merge_verse_meta(meta:Dictionary = {}, verse_meta:Dictionary = {}) -> Dictionary:
	meta.merge(verse_meta)
	return meta

#endregion

## Gets the hash for a book name
func get_book_hash(book_name: String) -> int:
	return hash(book_name)

## Gets the hash for a translation abbreviation
func get_translation_hash(translation_abbr: String) -> int:
	return hash(translation_abbr)

## Gets the hash for a scripture 
## This is just another version of get_scripture_id
func get_verse_hash(book: String, chapter: int, verse: int) -> int:
	return get_scripture_id(book, chapter, verse)

## Gets a scripture id based on Book, Chapter, Verse. 
## This is a very important function, used by many scripts. 
## The line var id_string = "%s-%s-%s" % [book, str(chapter), str(verse)] should not be changed
## because it is responsible for creating the consistent hash (id) of the verses. 
## This is done using a hash algorithm to create a unique identifier for the verse.
func get_scripture_id(book: String, chapter: int, verse: int) -> int:
	var id_string = "%s-%s-%s" % [book, str(chapter), str(verse)]
	return hash(id_string)

## Gets a connection id based on from_scripture and to_scripture.
## This is done using a hash algorithm to create a unique identifier for the connection.
func get_connection_id(from_book: String, from_chapter: int, from_verse: int, to_book: String, to_chapter: int, to_verse: int) -> int:
	var id_string:String = "%s-%s-%s-%s-%s-%s" % [from_book, str(from_chapter), str(from_verse), to_book, str(to_chapter), str(to_verse)]
	return hash(id_string)

## Checks if a translation is installed
func is_translation_installed(translation_abbr: String) -> bool:
	var translation_model:BibleTranslationModel = BibleTranslationModel.new()
	return translation_model.is_translation_installed(translation_abbr)

## Checks if a book is installed
func is_book_installed(translation: String, book_name: String) -> bool:
	var book_model:BookModel = BookModel.new(translation)
	return book_model.is_book_installed(book_name)

## Uninstall a book from a specific translation
func uninstall_book(translation: String, book: String):
	var translation_model = BibleTranslationModel.new()
	translation_model.translation_abbr = translation
	translation_model.uninstall_book(book)

## Uninstall a translation and all its associated books and verses
func uninstall_translation(translation: String):
	var translation_model = BibleTranslationModel.new()
	translation_model.translation_abbr = translation
	translation_model.get_translation(translation)
	translation_model.uninstall_translation()

#region Meta getters and setters

## Gets a verse meta entry
func get_verse_meta(verse_hash: int, key: String) -> Dictionary:
	var verse_meta_model = VerseMetaModel.new()
	return verse_meta_model.get_verse_meta(verse_hash, key)

## Gets all verse meta entries for a verse
func get_all_verse_meta(verse_hash: int) -> Array:
	var verse_meta_model = VerseMetaModel.new()
	return verse_meta_model.get_all_verse_meta(verse_hash)

## Gets all verse meta entries by key
func get_all_verse_meta_by_key(key: String) -> Array:
	var verse_meta_model = VerseMetaModel.new()
	return verse_meta_model.get_all_verse_meta_by_key(key)

## Sets a verse meta entry
func set_verse_meta(verse_hash: int, key: String, value: String):
	var verse_meta_model = VerseMetaModel.new()
	verse_meta_model.verse_hash = verse_hash
	verse_meta_model.key = key
	verse_meta_model.value = value
	verse_meta_model.save()

## Deletes all verse meta entries for a verse
func delete_verse_meta(verse_hash: int, key: String):
	var verse_meta_model = VerseMetaModel.new()
	verse_meta_model.verse_hash = verse_hash
	verse_meta_model.key = key
	verse_meta_model.delete()

## Deletes all verse meta entries by key
func delete_all_verse_meta(meta_key: String):
	var verse_meta_entries = get_all_verse_meta_by_key(meta_key)
	for entry in verse_meta_entries:
		delete_verse_meta(entry["verse_hash"], meta_key)

## Deletes a verse meta entry by id
func delete_verse_meta_by_id(id: int):
	var verse_meta_model = VerseMetaModel.new()
	verse_meta_model.id = id
	verse_meta_model.delete()

## Gets a book meta entry
func get_book_meta(book_hash: int, key: String) -> Dictionary:
	var book_meta_model = BookMetaModel.new()
	return book_meta_model.get_book_meta(book_hash, key)

## Gets all book meta entries for a book
func get_all_book_meta(book_hash: int) -> Array:
	var book_meta_model = BookMetaModel.new()
	return book_meta_model.get_all_book_meta(book_hash)

## Gets all book meta entries by key
func get_all_book_meta_by_key(key: String) -> Array:
	var book_meta_model = BookMetaModel.new()
	return book_meta_model.get_all_book_meta_by_key(key)

## Sets a book meta entry
func set_book_meta(book_hash: int, key: String, value: String):
	var book_meta_model = BookMetaModel.new()
	book_meta_model.book_hash = book_hash
	book_meta_model.key = key
	book_meta_model.value = value
	book_meta_model.save()

## Deletes a book meta entry
func delete_book_meta(book_hash: int, key: String):
	var book_meta_model = BookMetaModel.new()
	book_meta_model.book_hash = book_hash
	book_meta_model.key = key
	book_meta_model.delete()

## Deletes a book meta entry by id
func delete_book_meta_by_id(id: int):
	var book_meta_model = BookMetaModel.new()
	book_meta_model.id = id
	book_meta_model.delete()

## Deletes all book meta entries by key
func delete_all_book_meta(meta_key: String):
	var book_meta_entries = get_all_book_meta_by_key(meta_key)
	for entry in book_meta_entries:
		delete_book_meta(entry["book_hash"], meta_key)

## Gets a translation meta entry
func get_translation_meta(translation_hash: int, key: String) -> Dictionary:
	var translation_meta_model = TranslationMetaModel.new()
	return translation_meta_model.get_translation_meta(translation_hash, key)

## Gets all translation meta entries for a translation
func get_all_translation_meta(translation_hash: int) -> Array:
	var translation_meta_model = TranslationMetaModel.new()
	return translation_meta_model.get_all_translation_meta(translation_hash)

## Gets all translation meta entries by key
func get_all_translation_meta_by_key(key: String) -> Array:
	var translation_meta_model = TranslationMetaModel.new()
	return translation_meta_model.get_all_translation_meta_by_key(key)

## Sets a translation meta entry
func set_translation_meta(translation_hash: int, key: String, value: String):
	var translation_meta_model = TranslationMetaModel.new()
	translation_meta_model.translation_hash = translation_hash
	translation_meta_model.key = key
	translation_meta_model.value = value
	translation_meta_model.save()

## Deletes a translation meta entry
func delete_translation_meta(translation_hash: int, key: String):
	var translation_meta_model = TranslationMetaModel.new()
	translation_meta_model.translation_hash = translation_hash
	translation_meta_model.key = key
	translation_meta_model.delete()

## Deletes all translation meta entries by key
func delete_all_translation_meta(meta_key: String):
	var translation_meta_entries = get_all_translation_meta_by_key(meta_key)
	for entry in translation_meta_entries:
		delete_translation_meta(entry["translation_hash"], meta_key)

## Deletes a translation meta entry by id
func delete_translation_meta_by_id(id: int):
	var translation_meta_model = TranslationMetaModel.new()
	translation_meta_model.id = id
	translation_meta_model.delete()

## Gets unique verse meta entries for a verse
func get_unique_verse_meta() -> Array:
	var verse_meta_model = VerseMetaModel.new()
	return verse_meta_model.get_unique_verse_meta()

## Gets unique book meta entries for a book
func get_unique_book_meta() -> Array:
	var book_meta_model = BookMetaModel.new()
	return book_meta_model.get_unique_book_meta()

## Gets unique translation meta entries for a translation
func get_unique_translation_meta() -> Array:
	var translation_meta_model = TranslationMetaModel.new()
	return translation_meta_model.get_unique_translation_meta()

#endregion 

#region meta search 

## Gets verses by meta key.
## First, it gets all verse meta by exactly matching meta key. 
## Next, it gets all verses matching the verse_hashes found in meta rows.
func get_verses_by_meta_key(translation:String, meta_key:String) -> Array:
	var meta_results:Array = get_all_verse_meta_by_key(meta_key)
	var hash_array:Array[int] = []
	for result:Dictionary in meta_results:
		hash_array.append(result["verse_hash"])
	var verses:Array = []
	if hash_array.size() > 0:
		var verse_model = VerseModel.new(translation)
		verses = verse_model.get_verses_by_verse_hashes(hash_array)
	return verses

#endregion 

#region hash related getters

func get_verse_by_hash(translation: String, verse_hash: int) -> Dictionary:
	var verse_model = VerseModel.new(translation)
	var verse = verse_model.get_verse_by_hash(verse_hash)
	if verse == null:
		return {}
	return verse

func get_book_by_hash(translation: String, book_hash: int) -> Dictionary:
	var book_model = BookModel.new(translation)
	var book = book_model.get_book_by_hash(book_hash)
	if book == null:
		return {}
	return book

func get_translation_by_hash(translation_hash: int) -> Dictionary:
	var translation_model = BibleTranslationModel.new()
	var translation = translation_model.get_translation_by_hash(translation_hash)
	if translation == null:
		return {}
	return translation

#endregion 
