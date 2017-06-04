// Panic

Parse.Cloud.define("cleanPanics", function(request, response) {
    var query = new Parse.Query("Panics");
    var d = new Date();
 
    query.equalTo("active", true);
    query.find({
        success: function(results) {
            for (var i = 0; i < results.length; i++) {
                if (results[i].updatedAt < (d.getTime() - (60 * 1000))) {
                results[i].set("active",false);// = true;
            }
          }
 
          Parse.Object.saveAll(results,{
            success: function(list) {
                  // All the objects were saved.
                  response.success("ok - updated: " + results.length);  //saveAll is now finished and we can properly exit with confidence :-)
                    }, error: function(error) {
                    // An error occurred while saving one of the objects.
                    response.error("failure on saving list ");
                  },});
          // response.success("sweet");
        }
    })
});