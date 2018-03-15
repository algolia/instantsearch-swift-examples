var Handlebars = require("handlebars");

function basename(path) {
   return path.split("/").reverse()[0];
}

/**
 * Adds a `currentPage` CSS class when the 1st argument equals the currently processed file's path.
 */
module.exports = function(expectedPath, context) {
    if (context.data.root.path.href === expectedPath) {
        return new Handlebars.SafeString('class="currentPage"');
    } else {
        return "";
    }
}
