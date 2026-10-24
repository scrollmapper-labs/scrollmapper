extends BaseModel

class_name CrossReferenceModel

var id: int  # Added id variable
var from_book: String
var from_chapter: int
var from_verse: int
var to_book: String
var to_chapter_start: int
var to_chapter_end: int
var to_verse_start: int
var to_verse_end: int
var votes: int
var translation: String
var user_added: bool = false  # Changed useradded to user_added

func _init(translation: String):
	super._init()
	self.translation = translation.to_lower()
	create_table()

func get_create_table_query() -> String:
	return """
	CREATE TABLE IF NOT EXISTS cross_reference (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		from_book TEXT,
		from_chapter INTEGER,
		from_verse INTEGER,
		to_book TEXT,
		to_chapter_start INTEGER,
		to_chapter_end INTEGER,
		to_verse_start INTEGER,
		to_verse_end INTEGER,
		votes INTEGER,
		user_added BOOLEAN DEFAULT FALSE
	);
	"""

func save():
	if not cross_reference_exists(from_book, from_chapter, from_verse, to_book, to_chapter_start, to_chapter_end, to_verse_start, to_verse_end):
		var query = "INSERT INTO cross_reference (from_book, from_chapter, from_verse, to_book, to_chapter_start, to_chapter_end, to_verse_start, to_verse_end, votes, user_added) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
		execute_query(query, [from_book, from_chapter, from_verse, to_book, to_chapter_start, to_chapter_end, to_verse_start, to_verse_end, votes, user_added])

func get_all_cross_references():
	var query = "SELECT * FROM cross_reference;"
	return get_results(query)
	
## A fairly complex function to get the cross-references for a verse.
## If the source verse is in the Scrollmapper translation, it will also get the cross-references from the KJV translation
## by default, because normally cross-references are not cross-translation -- and Scrollmapper is considered a "translation"
## for technical reasons.
func get_cross_references_for_verse(from_book: String, from_chapter: int, from_verse: int) -> Array:
	var query = """
	SELECT 
		cr.id AS cross_reference_id, cr.from_book, cr.from_chapter, cr.from_verse, 
		cr.to_book, cr.to_chapter_start, cr.to_chapter_end, cr.to_verse_start, cr.to_verse_end, cr.votes, cr.user_added,
		v.id AS verse_id, v.book_id, v.chapter, v.verse, v.text,
		b.id AS book_id, b.book_name, b.translation_id,
		t.translation_abbr, t.title, t.license
	FROM 
		cross_reference cr
	JOIN 
		%s_books b ON cr.to_book = b.book_name
	JOIN 
		%s_verses v ON b.id = v.book_id
					AND (v.chapter > cr.to_chapter_start OR (v.chapter = cr.to_chapter_start AND v.verse >= cr.to_verse_start))
					AND (v.chapter < cr.to_chapter_end OR (v.chapter = cr.to_chapter_end AND v.verse <= cr.to_verse_end))
	JOIN 
		translations t ON b.translation_id = t.id
	WHERE 
		LOWER(cr.from_book) = LOWER(?)
		AND cr.from_chapter = ?
		AND cr.from_verse = ?
	""" % [translation, translation]

	var params:Array = [from_book, from_chapter, from_verse]
	if translation.to_lower() == "scrollmapper" and not get_results("SELECT name FROM sqlite_master WHERE name = 'kjv_verses' COLLATE NOCASE;").is_empty():
		query += """
		UNION
		SELECT 
			cr.id AS cross_reference_id, cr.from_book, cr.from_chapter, cr.from_verse, 
			cr.to_book, cr.to_chapter_start, cr.to_chapter_end, cr.to_verse_start, cr.to_verse_end, cr.votes, cr.user_added,
			v.id AS verse_id, v.book_id, v.chapter, v.verse, v.text,
			b.id AS book_id, b.book_name, b.translation_id,
			t.translation_abbr, t.title, t.license
		FROM 
			cross_reference cr
		JOIN 
			KJV_books b ON cr.to_book = b.book_name
		JOIN 
			KJV_verses v ON b.id = v.book_id
						AND (v.chapter > cr.to_chapter_start OR (v.chapter = cr.to_chapter_start AND v.verse >= cr.to_verse_start))
						AND (v.chapter < cr.to_chapter_end OR (v.chapter = cr.to_chapter_end AND v.verse <= cr.to_verse_end))
		JOIN 
			translations t ON b.translation_id = t.id
		WHERE 
			LOWER(cr.from_book) = LOWER(?)
			AND cr.from_chapter = ?
			AND cr.from_verse = ?
		"""

		params.append_array([from_book, from_chapter, from_verse])
	query += "ORDER BY votes DESC;"
	return get_results(query, params)

# New method to get a specific cross-reference
func get_cross_reference(id: int) -> Dictionary:
	var query = "SELECT * FROM cross_reference WHERE id = ?;"
	var result = get_results(query, [id])
	if result.size() > 0:
		return result[0]
	return {}

func get_cross_reference_exact(from_book: String, from_chapter: int, from_verse: int, to_book: String, to_chapter_start: int, to_chapter_end: int, to_verse_start: int, to_verse_end: int) -> Dictionary:
	var query = """
	SELECT * FROM cross_reference 
	WHERE 
		LOWER(from_book) = LOWER(?) AND 
		from_chapter = ? AND 
		from_verse = ? AND 
		LOWER(to_book) = LOWER(?) AND 
		to_chapter_start = ? AND 
		to_chapter_end = ? AND 
		to_verse_start = ? AND 
		to_verse_end = ?;
	"""
	var result = get_results(query, [from_book, from_chapter, from_verse, to_book, to_chapter_start, to_chapter_end, to_verse_start, to_verse_end])
	if result.size() > 0:
		return result[0]
	return {}

func cross_reference_exists(from_book: String, from_chapter: int, from_verse: int, to_book: String, to_chapter_start: int, to_chapter_end: int, to_verse_start: int, to_verse_end: int) -> bool:
	var result = get_cross_reference_exact(from_book, from_chapter, from_verse, to_book, to_chapter_start, to_chapter_end, to_verse_start, to_verse_end)
	return result.size() > 0

func delete():
	if id != null:
		var query = "DELETE FROM cross_reference WHERE id = ?;"
		execute_query(query, [id])
	else:
		print("Cross-reference ID is not set, cannot delete the entry.")

func get_unique_books() -> Array:
	var query = "SELECT DISTINCT from_book FROM cross_reference;"
	var results = get_results(query)
	var books = []
	for result in results:
		books.append(result["from_book"])
	return books

func get_cross_references_by_books(from_books: Array, _user_added: bool = false) -> Array:
	if from_books.is_empty():
		return []
	
	var placeholders = PackedStringArray()
	var params = []
	for book in from_books:
		placeholders.append("?")
		params.append(book)
	
	var query = "SELECT * FROM cross_reference WHERE from_book IN (%s)" % ", ".join(placeholders)
	if _user_added:
		query += " AND user_added = ?"
		params.append(true)
	
	return get_results(query, params)
