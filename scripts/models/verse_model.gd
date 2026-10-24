extends BaseModel

class_name VerseModel

#region Main variables...
var id: int = 0
var verse_hash: int = 0
var book_id: int = 0
var chapter: int = 0
var verse: int = 0
var text: String = ""
var translation: String = ""
#endregion

func _init(_translation: String):
	super._init()
	self.translation = _translation.to_lower()
	create_table()

func get_create_table_query() -> String:
	return """
	CREATE TABLE IF NOT EXISTS %s_verses (
		id INTEGER PRIMARY KEY,
		verse_hash INTEGER UNIQUE,
		book_id INTEGER,
		chapter INTEGER,
		verse INTEGER,
		text TEXT,
		FOREIGN KEY(book_id) REFERENCES %s_books(id)
	);
	""" % [translation, translation]

func bulk_save(verses: Array):
	if verses.size() == 0:
		return
	
	var insert_query = "INSERT INTO %s_verses (id, verse_hash, book_id, chapter, verse, text) VALUES " % translation
	var values = []
	var params = []
	
	for verse in verses:
		verse_hash = verse.get_verse_hash()
		values.append("(?, ?, ?, ?, ?, ?)")
		params.append(verse_hash)
		params.append(verse_hash)
		params.append(verse.book_id)
		params.append(verse.chapter)
		params.append(verse.verse)
		params.append(verse.text)
	
	insert_query += ",".join(values) + " ON CONFLICT(id) DO UPDATE SET verse_hash = excluded.verse_hash, book_id = excluded.book_id, chapter = excluded.chapter, verse = excluded.verse, text = excluded.text;"
	execute_query(insert_query, params)

func save():
	# Check if verse already exists
	var query = "SELECT id FROM %s_verses WHERE book_id = ? AND chapter = ? AND verse = ?;" % translation
	var result = get_results(query, [book_id, chapter, verse])
	
	if result.size() > 0:
		# Update existing verse
		var update_query = "UPDATE %s_verses SET text = ?, verse_hash = ? WHERE book_id = ? AND chapter = ? AND verse = ?;" % translation
		execute_query(update_query, [text, get_verse_hash(), book_id, chapter, verse])
	else:
		# Insert new verse
		var insert_query = "INSERT INTO %s_verses (id, verse_hash, book_id, chapter, verse, text) VALUES (?, ?, ?, ?, ?, ?);" % translation
		get_verse_hash() 
		execute_query(insert_query, [verse_hash, verse_hash, book_id, chapter, verse, text])

func get_all_verses() -> Array:
	var query = """
	SELECT v.id AS verse_id, v.verse_hash, v.book_id, v.chapter, v.verse, v.text, 
	b.id AS book_id, b.book_name, b.translation_id,
	t.translation_abbr, t.title, t.license 
	FROM %s_verses v
	JOIN %s_books b ON v.book_id = b.id
	JOIN translations t ON b.translation_id = t.id
	ORDER BY v.book_id, v.chapter, v.verse
	""" % [translation, translation]
	return get_results(query)

func get_verse(book_id: int, chapter: int, verse: int) -> Dictionary:
	var query = """
	SELECT v.id AS verse_id, v.verse_hash, v.book_id, v.chapter, v.verse, v.text, 
	b.id AS book_id, b.book_name, b.translation_id,
	t.translation_abbr, t.title, t.license 
	FROM %s_verses v
	JOIN %s_books b ON v.book_id = b.id
	JOIN translations t ON b.translation_id = t.id
	WHERE v.book_id = ? AND v.chapter = ? AND v.verse = ?
	""" % [translation, translation]
	var result = get_results(query, [book_id, chapter, verse])
	if result.size() > 0:
		self.id = result[0]["verse_id"]
		self.verse_hash = result[0]["verse_hash"]
		self.book_id = result[0]["book_id"]
		self.chapter = result[0]["chapter"]
		self.verse = result[0]["verse"]
		self.text = result[0]["text"]
		return result[0]
	else:
		return {}

# Get verses by book, chapter, or specific verse
func get_verses(book_name: String, chapter: int = -1, verse: int = -1) -> Array:
	var book_model = BookModel.new(translation)
	book_model.find_book_by_name(book_name)
	var book_id = book_model.id

	var query = """
	SELECT v.id AS verse_id, v.verse_hash, v.book_id, v.chapter, v.verse, v.text, 
	b.id AS book_id, b.book_name, b.translation_id,
	t.translation_abbr, t.title, t.license 
	FROM %s_verses v
	JOIN %s_books b ON v.book_id = b.id
	JOIN translations t ON b.translation_id = t.id
	WHERE v.book_id = ?
	""" % [translation, translation]
	var params = [book_id]

	if chapter != -1:
		query += " AND v.chapter = ?"
		params.append(chapter)
	if verse != -1:
		query += " AND v.verse = ?"
		params.append(verse)

	query += " ORDER BY v.chapter, v.verse"

	return get_results(query, params)

# Function to get verses by ids
func get_verses_by_ids(verse_ids: Array) -> Array:
	if verse_ids.is_empty():
		return []

	var placeholder_list = []
	for verse_id in verse_ids:
		placeholder_list.append("?")
	var placeholders = ",".join(placeholder_list)
	
	var order_cases = []
	for idx in range(verse_ids.size()):
		order_cases.append("WHEN %d THEN %d" % [verse_ids[idx], idx])
	var order_clause = " ".join(order_cases)
	
	var query = """
	SELECT v.id AS verse_id, v.verse_hash, v.book_id, v.chapter, v.verse, v.text, 
	b.id AS book_id, b.book_name, b.translation_id,
	t.translation_abbr, t.title, t.license 
	FROM %s_verses v
	JOIN %s_books b ON v.book_id = b.id
	JOIN translations t ON b.translation_id = t.id
	WHERE v.id IN (%s)
	ORDER BY CASE v.id %s END
	""" % [translation, translation, placeholders, order_clause]

	return get_results(query, verse_ids)

# Function to get a verse by its hash
func get_verse_by_hash(verse_hash: int) -> Dictionary:
	var query = """
	SELECT v.id AS verse_id, v.verse_hash, v.book_id, v.chapter, v.verse, v.text, 
	b.id AS book_id, b.book_name, b.translation_id,
	t.translation_abbr, t.title, t.license 
	FROM %s_verses v
	JOIN %s_books b ON v.book_id = b.id
	JOIN translations t ON b.translation_id = t.id
	WHERE v.verse_hash = ?
	""" % [translation, translation]
	var result = get_results(query, [verse_hash])
	if result.size() > 0:
		self.id = result[0]["verse_id"]
		self.verse_hash = result[0]["verse_hash"]
		self.book_id = result[0]["book_id"]
		self.chapter = result[0]["chapter"]
		self.verse = result[0]["verse"]
		self.text = result[0]["text"]
		return result[0]
	else:
		return {}

# Function to get verses by verse hashes
func get_verses_by_verse_hashes(verse_hashes: Array) -> Array:
	if verse_hashes.is_empty():
		return []

	var placeholder_list = []
	for verse_hash in verse_hashes:
		placeholder_list.append("?")
	var placeholders = ",".join(placeholder_list)
	
	var order_cases = []
	for idx in range(verse_hashes.size()):
		order_cases.append("WHEN %d THEN %d" % [verse_hashes[idx], idx])
	var order_clause = " ".join(order_cases)
	
	var query = """
	SELECT v.id AS verse_id, v.verse_hash, v.book_id, v.chapter, v.verse, v.text, 
	b.id AS book_id, b.book_name, b.translation_id,
	t.translation_abbr, t.title, t.license 
	FROM %s_verses v
	JOIN %s_books b ON v.book_id = b.id
	JOIN translations t ON b.translation_id = t.id
	WHERE v.verse_hash IN (%s)
	ORDER BY CASE v.verse_hash %s END
	""" % [translation, translation, placeholders, order_clause]

	return get_results(query, verse_hashes)

# Get verses by range
func get_verses_by_range(start_book: String, start_chapter: int, start_verse: int, end_book: String, end_chapter: int, end_verse: int) -> Array:
	var start_book_model = BookModel.new(translation)
	start_book_model.get_book_by_name(start_book)
	var start_book_id = start_book_model.id

	var end_book_model = BookModel.new(translation)
	end_book_model.get_book_by_name(end_book)
	var end_book_id = end_book_model.id

	var query = """
	SELECT v.id AS verse_id, v.verse_hash, v.book_id, v.chapter, v.verse, v.text, 
	b.id AS book_id, b.book_name, b.translation_id,
	t.translation_abbr, t.title, t.license 
	FROM %s_verses v
	JOIN %s_books b ON v.book_id = b.id
	JOIN translations t ON b.translation_id = t.id
	WHERE (v.book_id > ? OR (v.book_id = ? AND (v.chapter > ? OR (v.chapter = ? AND v.verse >= ?))))
	AND (v.book_id < ? OR (v.book_id = ? AND (v.chapter < ? OR (v.chapter = ? AND v.verse <= ?))))
	ORDER BY v.book_id, v.chapter, v.verse
	""" % [translation, translation]

	var params = [
		start_book_id, start_book_id, start_chapter, start_chapter, start_verse,
		end_book_id, end_book_id, end_chapter, end_chapter, end_verse
	]

	return get_results(query, params)

# Function to get all chapter numbers in a book
func get_all_chapter_numbers(book_name: String) -> Array:
	var book_model = BookModel.new(translation)
	book_model.find_book_by_name(book_name)
	var book_id = book_model.id

	var query = "SELECT DISTINCT chapter FROM %s_verses WHERE book_id = ? ORDER BY chapter;" % translation
	
	return get_results(query, [book_id])

# Function to get all verse numbers in a chapter
func get_all_verse_numbers(book_name: String, chapter: int) -> Array:
	var book_model = BookModel.new(translation)
	book_model.find_book_by_name(book_name)
	var book_id = book_model.id

	var query = "SELECT DISTINCT verse FROM %s_verses WHERE book_id = ? AND chapter = ? ORDER BY verse;" % translation
	
	return get_results(query, [book_id, chapter])

#region Text Search

# Function to search text in translation
func search_text(phrase: String, book_name: String = "", chapter: int = -1) -> Array:
	var query = """
	SELECT v.id AS verse_id, v.verse_hash, v.book_id, v.chapter, v.verse, v.text, 
	b.id AS book_id, b.book_name, b.translation_id,
	t.translation_abbr, t.title, t.license 
	FROM %s_verses v
	JOIN %s_books b ON v.book_id = b.id
	JOIN translations t ON b.translation_id = t.id
	WHERE v.text LIKE ?
	""" % [translation, translation]
	var params = ["%%%s%%" % phrase]

	if book_name != "":
		var book_model = BookModel.new(translation)
		book_model.find_book_by_name(book_name)
		var book_id = book_model.id
		query += " AND v.book_id = ?"
		params.append(book_id)

	if chapter != -1:
		query += " AND v.chapter = ?"
		params.append(chapter)

	query += " ORDER BY v.book_id, v.chapter, v.verse"

	return get_results(query, params)
#endregion

# New delete function
func delete():
	if id != null:
		var query = "DELETE FROM %s_verses WHERE id = ?;" % translation
		execute_query(query, [id])
	else:
		print("Verse ID is not set, cannot delete the verse.")

func delete_by_book_id(book_id: int):
	var query = "DELETE FROM %s_verses WHERE book_id = ?;" % translation
	execute_query(query, [book_id])

## Gets the unique hash for the verse. 
func get_verse_hash() -> int:
	var book_model = BookModel.new(translation)
	book_model.get_book_by_id(self.book_id)
	var book_name = book_model.book_name
	self.verse_hash = ScriptureService.get_scripture_id(book_name, self.chapter, self.verse)
	return self.verse_hash
