extends Node

## Initializes with a GephiNetwork object, and populates a valid gexf format string for Gephi.
class_name GephiGexf

var main_template:String = ''' 
<?xml version="1.0" encoding="UTF-8"?>
<gexf xmlns="http://gexf.net/1.3" version="1.3">
	<meta lastmodifieddate="{lastmodifieddate}">
		<creator>{creator}</creator>
		<description>{description}</description>
	</meta>
	<graph mode="static" defaultedgetype="directed">
		<attributes class="node">
			{attributes}
		</attributes>
		<nodes>
			{nodes}
		</nodes>
		<edges>
			{edges}
		</edges>
	</graph>
</gexf>
'''

var attribute_template:String = '''
<attribute id="{id}" title="{title}" type="{type}" />
'''

var node_template:String = '''
<node id="{id}" label="{label}">
	<attvalues>
		<attvalue for="{scripture_text_id}" value="{scripture_text}" />
		<attvalue for="{scripture_location_id}" value="{scripture_location}" />
		<attvalue for="{translation_id}" value="{translation}" />
		<attvalue for="{book_id}" value="{book}" />
		<attvalue for="{chapter_id}" value="{chapter}" />
		<attvalue for="{verse_id}" value="{verse}" />
		{other_atvalues}
	</attvalues>
</node>
'''

var edge_template:String = '''
<edge id="{id}" source="{source}" target="{target}" weight="{weight}" />
'''

var gexf_xml:String = ""

func _init(gephi_network: GephiNetwork) -> void:
	var nodes_str:PackedStringArray = PackedStringArray()
	var edges_str:PackedStringArray = PackedStringArray()
	var attributes_str:PackedStringArray = PackedStringArray()

	# Create attributes from main network elements first
	var scripture_text_id = str(hash("scripture_text"))
	var scripture_location_id = str(hash("scripture_location"))
	var translation_id = str(hash("translation"))
	var book_id = str(hash("book"))
	var chapter_id = str(hash("chapter"))
	var verse_id = str(hash("verse"))

	# Attribute for scripture text
	attributes_str.append(attribute_template.format({
		"id": scripture_text_id,
		"title": "scripture_text",
		"type": "string"
	}))
	# Attribute for scripture location
	attributes_str.append(attribute_template.format({
		"id": scripture_location_id,
		"title": "scripture_location",
		"type": "string"
	}))
	# Attribute for translation
	attributes_str.append(attribute_template.format({
		"id": translation_id,
		"title": "translation",
		"type": "string"
	}))
	# Attribute for book
	attributes_str.append(attribute_template.format({
		"id": book_id,
		"title": "book",
		"type": "string"
	}))
	# Attribute for chapter
	attributes_str.append(attribute_template.format({
		"id": chapter_id,
		"title": "chapter",
		"type": "integer"
	}))
	# Attribute for verse
	attributes_str.append(attribute_template.format({
		"id": verse_id,
		"title": "verse",
		"type": "integer"
	}))

	# Add more attributes based on verse meta keys
	for verse_meta_key in gephi_network.verse_meta_keys:
		var id = str(hash(verse_meta_key))
		attributes_str.append(attribute_template.format({
			"id": id,
			"title": verse_meta_key.xml_escape(true),
			"type": "string"
		}))

	# Construct the nodes 
	for node_id in gephi_network.nodes.keys():
		var node = gephi_network.nodes[node_id]
		var label = "%s %s:%s" % [node.book, str(node.chapter), str(node.verse)]
		var other_atvalues:String = create_meta_attributes(gephi_network, node.scripture_hash)

		# Add verse meta data as attributes
		nodes_str.append(node_template.format({
			"id": node_id,
			"label": label.xml_escape(true),
			"scripture_text_id": scripture_text_id,
			"scripture_text": node.scripture_text.xml_escape(true),
			"scripture_location_id": scripture_location_id,
			"scripture_location": label.xml_escape(true),
			"translation_id": translation_id,
			"translation": node.translation.xml_escape(true),
			"book_id": book_id,
			"book": node.book.xml_escape(true),
			"chapter_id": chapter_id,
			"chapter": str(node.chapter),
			"verse_id": verse_id,
			"verse": str(node.verse), 
			"other_atvalues": other_atvalues
		}))
	
	# Construct the edges
	for edge_id in gephi_network.edges.keys():
		var edge = gephi_network.edges[edge_id]
		
		edges_str.append(edge_template.format({
			"id": edge_id,
			"source": str(edge.source),
			"target": str(edge.target),
			"weight": str(edge.weight)
		}))
	
	var gexf_str = main_template.format({
		"lastmodifieddate": gephi_network.last_modified_date,
		"creator": gephi_network.creator.xml_escape(true),
		"description": gephi_network.description.xml_escape(true),
		"attributes": "\n".join(attributes_str),
		"nodes": "\n".join(nodes_str),
		"edges": "\n".join(edges_str)
	})
	
	gexf_xml = gexf_str

## Creates the meta attributes for a verse.
func create_meta_attributes(gephi_network:GephiNetwork, verse_hash: int) -> String:
	if not gephi_network.verse_meta.has(verse_hash):
		return ""
	
	var meta_attributes: PackedStringArray = PackedStringArray()
	for key in gephi_network.verse_meta[verse_hash].keys():
		var meta: GephiMeta = gephi_network.verse_meta[verse_hash][key]
		meta_attributes.append('<attvalue for="%s" value="%s" />' % [str(hash(meta.key)), meta.value.xml_escape(true)])
	
	return "\n".join(meta_attributes)

## Returns the gexf xml string.
func get_gexf_xml() -> String:
	return gexf_xml