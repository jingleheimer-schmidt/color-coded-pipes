// Get all open documents
var docs = app.documents;

for (var d = 0; d < docs.length; d++) {
    var doc = docs[d];
    app.activeDocument = doc; // Activate the document
    var layers = doc.layers;
    var layers_length = layers.length;

    // hide all layers
    for (var i = 0; i < layers_length; i++) {
        var layer = layers[i];
        layer.visible = false;
    }

    for (var i = 0; i < layers_length; i++) {
        var layer = layers[i];

        // show the layer if it's names "overlay"
        if (layer.name == "overlay") {
            layer.visible = true;
        } else {
            continue;
        }

        // Export the .png file
        var layerName = layer.name + "-";
        var fileName = layerName + doc.name + ".png"; // overlay-<document_name>.png
        fileName = fileName.replace(".psd", ""); // Remove .psd extension (if it exists)
        var folderName = "overlay";
        
        if (!Folder(doc.path + "/" + folderName).exists) {
            new Folder(doc.path + "/" + folderName).create();
        }

        // Export full resolution PNG
        var file = new File(doc.path + "/" + folderName + "/" + fileName);
        var exportOptions = new ExportOptionsSaveForWeb();
        exportOptions.format = SaveDocumentType.PNG;
        exportOptions.PNG8 = false;
        exportOptions.transparency = true;
        doc.exportDocument(file, ExportType.SAVEFORWEB, exportOptions);
    };

    // show all the layers again
    for (var i = 0; i < layers_length; i++) {
        var layer = layers[i];
        layer.visible = true;
    }

    // save the document
    doc.save();
}
