extends Node

class_name Types

enum LevelType{
	HOME,
	VX_GRAPH,
	EXPLORER,
	BOOK_LIBRARY,
	READER,
	META_EDITOR,
	SPLASH,
}

enum DataDir{
	DATA,
	SOURCES,
	USER,
}

enum SearchScope {
	ALL_SCRIPTURE,
	COMMON_CANNONICAL,
	EXTRA_CANNONICAL,
}

enum VerseType{
	BASIC,
	CROSS_REFERENCE,
	MINIMAL,
	VX_LISTING, 
}

#region VXNode

# VXNode is a node that represents a verse or a set of verses in the scripture.

# SocketType Input + Linear = Top
# SocketType Output + Linear = Bottom

enum SocketType { 
	INPUT, # Input is top or left of a node. 
	OUTPUT, # Output is bottom or right of a node.
}

enum SocketDirectionType { 
	LINEAR, # Linear represents downward flow of scripture, such as when you read a bible book.
	PARALLEL, # Parallel represents a side by side comparison of scripture, such as when you compare two bible verses or sets of verses.
}

#endregion
