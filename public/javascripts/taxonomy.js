var base_url = "/admin/taxonomies/" + taxonomy_id + "/taxons/";
var creating = false;
var delete_confirmed = false;
var last_rollback = null;


var show_progress = function(){
	jQuery("#progress").show();
	jQuery("#ajax_error").hide();
}

var hide_progress = function(){
	jQuery("#progress").hide();
}

var handle_ajax_error = function(XMLHttpRequest, textStatus, errorThrown){
	jQuery.tree_rollback(last_rollback);
	jQuery("#progress").hide();
	jQuery("#ajax_error").show().html("<strong>" + server_error + "</strong><br/>" + taxonomy_tree_error);
};

var handle_move = function(li, target, droppped, tree, rb) {
	last_rollback = rb;
  var position = jQuery(li).prevAll().length;

  var parent = -1;
  
  if(droppped=='inside'){
    parent = target;
  }else if(droppped=='after'){
    parent = jQuery(target).parents()[1];
  }else if(droppped=='before'){
    parent = jQuery(target).parents()[1];
  }
 
  jQuery.ajax({
    type: "POST",
    url: base_url + li.id,
    data: ({_method: "put", "taxon[parent_id]": parent.id, "taxon[position]": position, authenticity_token: AUTH_TOKEN}),
		beforeSend: show_progress,
    error: handle_ajax_error,
		success: hide_progress
  });
        
  return true
};

var handle_dblclick = function(li, tree) {
  tree.rename();
};

var handle_create = function(parent, sib, created, tree, rb){
	last_rollback = rb;
	creating=true;	
};

var handle_created = function(id,result) {
	hide_progress();
	
	jQuery.tree_reference('taxonomy_tree').selected.attr('id', id);
}

var handle_rename = function(li, bl, tree, rb) {
  var name = jQuery(li).children()[0].innerHTML;
  
	if (creating){
		//actually creating new
		var position = jQuery(li).prevAll().length;
		var parent = jQuery(li).parents()[1];
	  
		jQuery.ajax({
	    type: "POST",
	    url: base_url,
	    data: ({"taxon[name]": name, "taxon[parent_id]": parent.id, "taxon[position]": position, authenticity_token: AUTH_TOKEN}),
	    beforeSend: show_progress,
			error: handle_ajax_error,
	  	success: handle_created
	  });	
	
		creating = false;
	}else{
		//just renaming
		last_rollback = rb;
		
	  jQuery.ajax({
	    type: "POST",
	    url: base_url + li.id,
	    data: ({_method: "put", "taxon[name]": name, authenticity_token: AUTH_TOKEN}),
	    beforeSend: show_progress,
			error: handle_ajax_error,
			success: hide_progress        
	  });
	}
};

var handle_before_delete = function(li){
	jQuery.alerts.dialogClass = "spree";
	
	if (!delete_confirmed){
		jConfirm('Are you sure you want to delete this taxon?', 'Confirm Taxon Deletion', function(r) {
			if(r){
				delete_confirmed = true;
				jQuery.tree_reference('taxonomy_tree').remove(li);
			}
		});
	}
	
	return delete_confirmed;
};

var handle_delete = function(li, tree, rb){
	last_rollback = rb;
		
	jQuery.ajax({
    type: "POST",
    url: base_url + li.id,
    data: ({_method: "delete", authenticity_token: AUTH_TOKEN}),
   	beforeSend: show_progress,
		error: handle_ajax_error,
		success: hide_progress		
  });

	delete_confirmed = false;
};

var debug_holder = function(node, tree){
	if (true) {
		var noop = false;
	}
	return noop;
}

var node_has_product_group = function(node) {
	return $(node[0]).hasClass("has-product-group");
}

var node_can_add_product_group = function(node) {
	if (node_has_product_group(node)) return false;
	return $(node[0]).hasClass("leaf");
}

var taxon_product_group_remove = function(li) {
	var taxon_id= li.id;
	var product_group_id = $(li).children('.product-group')[0].id;
	$.ajax({
		type: "DELETE",
		url: "/admin/taxons/" + taxon_id + "/product_groups/" + product_group_id + "/remove",
		data: ({_method: "post", authenticity_token: AUTH_TOKEN}),
		beforeSend: show_progress,
		error: handle_ajax_error,
		success: function (data, textStatus) { taxon_update_node(li, data); hide_progress(); }
	});	
};

var taxon_update_node = function(node, html){
	$(node).html(html);
//	tree_component.reselect($(node));
};

var taxon_product_group_add = function(li) {
	var taxon_id = li.id;
    product_group_select_taxon_id = taxon_id;
	product_group_select_glob = {
		taxon_id : taxon_id,
		success_handler: function(data) { alert(data); taxon_update_node(li, data); },
		failure_handler: function(response) {},
	};
	$('#product-group-select').show();	
};

conf = { 
  ui : {
    theme_path  : "/javascripts/jsTree/source/themes/",
		theme_name	: "spree",
    context     : [ 
        {
            id      : "create",
            label   : "Create", 
            icon    : "create.png",
            visible : function (NODE, TREE_OBJ) { if(NODE.length != 1) return false; return TREE_OBJ.check("creatable", NODE); }, 
            action  : function (NODE, TREE_OBJ) { TREE_OBJ.create({ attributes : { 'rel' : 'taxon' } }, TREE_OBJ.get_node(NODE)); } 
        },
        "separator",
        { 
            id      : "rename",
            label   : "Rename", 
            icon    : "rename.png",
            visible : function (NODE, TREE_OBJ) { if(NODE.length != 1 || NODE[0].id == 'root') return false; return TREE_OBJ.check("renameable", NODE); }, 
            action  : function (NODE, TREE_OBJ) { jQuery.each(NODE, function () { TREE_OBJ.rename(this); }); } 
        },
        { 
            id      : "delete",
            label   : "Delete",
            icon    : "remove.png",
            visible : function (NODE, TREE_OBJ) { var ok = true; jQuery.each(NODE, function () { if(TREE_OBJ.check("deletable", this) == false || this.id == 'root') ok = false; return false; }); return ok; }, 
            action  : function (NODE, TREE_OBJ) { jQuery.each(NODE, function () { TREE_OBJ.remove(this); }); } 
        },
        "separator",
        { 
            id      : "cut",
            label   : "Cut",
            icon    : "cut.png",
            visible : function (NODE, TREE_OBJ) { if(NODE.length != 1 || NODE[0].id == 'root') return false; return true; }, 
            action  : function (NODE, TREE_OBJ) { TREE_OBJ.cut(); jQuery(NODE).hide(); } 
        },
        { 
            id      : "paste",
            label   : "Paste",
            icon    : "paste.png",
            visible : function (NODE, TREE_OBJ) { if(NODE.length != 1 || NODE[0].id == 'root') return false; return true; }, 
            action  : function (NODE, TREE_OBJ) { TREE_OBJ.open_branch(NODE); TREE_OBJ.paste(NODE); $(NODE).children(":last").children(":last").show(); } 
        },
		"separator",
		{
			id		: "add_product_group",
			label	: "Add Product Group",
			icon	: "create.png",
			visible	: function (NODE, TREE_OBJ) { return node_can_add_product_group(NODE); },
			action	: function (NODE, TREE_OBJ) { taxon_product_group_add(NODE[0]); return true; }
		},
		{
			id		: "rm_product_group",
			label	: "Remove Product Group",
			icon	: "remove.png",
			visible	: function (NODE, TREE_OBJ) { return node_has_product_group(NODE); },
			action	: function (NODE, TREE_OBJ) { taxon_product_group_remove(NODE[0]); return true; }
		}
    ]
  },
  lang : {
         new_node    : new_taxon,
         loading     : loading + "..."
  },
  rules : {
    droppable : [ "tree-drop" ],
    multiple : true,
    deletable : ["taxon"],
    draggable : ["taxon"],
	 	dragrules : [ "taxon * taxon", "taxon inside root", ],
		renameable  : ["taxon"]
  },
  callback : {
    onmove: handle_move,
    ondblclk: handle_dblclick,
    onrename: handle_rename,
		oncreate: handle_create,
		beforedelete: handle_before_delete,
		ondelete: handle_delete
  }
};

jQuery(document).ready(function(){
	
  tax_tree = jQuery.tree_create();
  tax_tree.init(jQuery("#taxonomy_tree"), jQuery.extend({},conf));
  
	jQuery(document).keypress(function(e){
    //surpress form submit on enter/return
    if (e.keyCode == 13){
        e.preventDefault();
    } 
  });
});
