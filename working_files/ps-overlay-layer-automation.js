// Get all open documents
var docs = app.documents;

for (var d = 0; d < docs.length; d++) {
    var doc = docs[d];
    app.activeDocument = doc; // Activate the document
    var layers = doc.layers;
    var layers_length = layers.length;

    // Make only layes named "Layer 2" visible
    for (var i = 0; i < layers_length; i++) {
        var layer = layers[i];
        if (layer.name == "Layer 2") {
            layer.visible = true;
        } else {
            layer.visible = false;
        }
    }

    // Export the visible layers
    for (var i = 0; i < layers_length; i++) {
        var layer = layers[i];
        if (layer.visible) {
            // var adjustmentName = layer.name.replace(/\s+/g, "_"); // Replace spaces with underscores
            var layerName = "overlay-";
            var fileName = layerName + doc.name + ".png";
            var halfResolutionFileName = layerName + doc.name + "@0.5x.png";
            fileName = fileName.replace(".psd", ""); // Remove .psd extension (if it exists)
            halfResolutionFileName = halfResolutionFileName.replace(".psd", ""); // Remove .psd extension (if it exists)
            var folderName = "overlay-" + doc.name;
            folderName = folderName.replace(".psd", ""); // Remove .psd extension (if it exists)
            folderName = folderName.replace("hr-", ""); // Remove hr- prefix (if it exists)

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

            // Export half resolution PNG
            var halfResolutionFile = new File(doc.path + "/" + folderName + "/" + halfResolutionFileName);
            var halfResolutionOptions = new ExportOptionsSaveForWeb();
            halfResolutionOptions.format = SaveDocumentType.PNG;
            halfResolutionOptions.PNG8 = false;
            halfResolutionOptions.transparency = true;
            halfResolutionOptions.quality = 100; // Set quality to 100% for half resolution
            halfResolutionOptions.optimized = true; // Optimize for web
            halfResolutionOptions.interlaced = false; // Disable interlacing

            // Resize the document to half the dimensions
            var originalWidth = doc.width;
            var originalHeight = doc.height;
            doc.resizeImage(originalWidth / 2, originalHeight / 2);

            doc.exportDocument(halfResolutionFile, ExportType.SAVEFORWEB, halfResolutionOptions);

            // Undo the resize operation to restore the original document size
            app.activeDocument.activeHistoryState = app.activeDocument.historyStates[app.activeDocument.historyStates.length - 2];

        }
    }

    // for (var i = 0; i < layers_length; i++) {
    //     var layer = layers[i];
    //     layer.visible = true;
        
    //     var adjustmentName = layer.name.replace(/\s+/g, "_"); // Replace spaces with underscores
    //     var fileName = adjustmentName + "-" + doc.name + ".png";
    //     var halfResolutionFileName = adjustmentName + "-" + doc.name + "@0.5x.png";
    //     fileName = fileName.replace(".psd", ""); // Remove .psd extension (if it exists)
    //     halfResolutionFileName = halfResolutionFileName.replace(".psd", ""); // Remove .psd extension (if it exists)
    //     var folderName = doc.name + "";
    //     folderName = folderName.replace(".psd", ""); // Remove .psd extension (if it exists)
    //     folderName = folderName.replace("hr-", ""); // Remove hr- prefix (if it exists)
        
    //     if (fileName.search("Layer") == -1) {

    //         if (!Folder(doc.path + "/" + folderName).exists) {
    //             new Folder(doc.path + "/" + folderName).create();
    //         }

    //         // Export full resolution PNG
    //         var file = new File(doc.path + "/" + folderName + "/" + fileName);
    //         var exportOptions = new ExportOptionsSaveForWeb();
    //         exportOptions.format = SaveDocumentType.PNG;
    //         exportOptions.PNG8 = false;
    //         exportOptions.transparency = true;
    //         doc.exportDocument(file, ExportType.SAVEFORWEB, exportOptions);

    //         // Export half resolution PNG
    //         var halfResolutionFile = new File(doc.path + "/" + folderName + "/" + halfResolutionFileName);
    //         var halfResolutionOptions = new ExportOptionsSaveForWeb();
    //         halfResolutionOptions.format = SaveDocumentType.PNG;
    //         halfResolutionOptions.PNG8 = false;
    //         halfResolutionOptions.transparency = true;
    //         halfResolutionOptions.quality = 100; // Set quality to 100% for half resolution
    //         halfResolutionOptions.optimized = true; // Optimize for web
    //         halfResolutionOptions.interlaced = false; // Disable interlacing

    //         // Resize the document to half the dimensions
    //         var originalWidth = doc.width;
    //         var originalHeight = doc.height;
    //         doc.resizeImage(originalWidth / 2, originalHeight / 2);

    //         doc.exportDocument(halfResolutionFile, ExportType.SAVEFORWEB, halfResolutionOptions);

    //         // Undo the resize operation to restore the original document size
    //         app.activeDocument.activeHistoryState = app.activeDocument.historyStates[app.activeDocument.historyStates.length - 2];

    //         layer.visible = false;
    //     }
    // }
}
