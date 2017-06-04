// Panic

// Handles a Panic
Parse.Cloud.define("handlePanic", function(request, response) {
  var User = Parse.Object.extend("User");
  var user = new User();
  user.id = request.params["userId"];

  var Panic = Parse.Object.extend("Panics");
  var panic = new Panic();
  var point = new Parse.GeoPoint({latitude: request.params["lat"], longitude: request.params["long"]});

  panic.id = request.params["objectId"];
  panic.set("active", true);
  panic.set("details", request.params["details"]);
  panic.set("location", point);
  panic.set("user", user);

  panic.save(null, {
    success: function(results) {
      response.success('New object created with objectId: ' + results.id);
    },
    error: function(results, error) {
      alert('Failed to create new object, with error code: ' + error.message);
      response.error("nope " + error.message);
    }
  });
});

// Gets a users details and returns the user object
// Parse.Cloud.define("getUserDetails", function(request, response) {
  function getUserDetails(userObjectId) {
    // var User = Parse.Query.extend("User");
    var query = new Parse.Query(Parse.User);
    query.equalTo("objectId", userObjectId);
    query.find({
      success: function(user) {
        response.success(user[0].get('groups'));
        return user[0];

      },
      error: function(user, error) {
        response.error(error);
      }
    });
  }
  // getUserDetails(request.params["objectId"]);
// });

Parse.Cloud.define("sendPush", function(request, response) {
  // var user = getUserDetails(request.params["objectId"]);

  // var groups = user.get("groups");
  // groups = request.params['channel'];
  groups = ["Testing"];
  Parse.Push.send({
    channels: [groups],
    data: {
      alert: "The Giants won against the Mets 2-3. again."
    }
  }, {
    success: function() {
      response.success("Push was successful" + user);
    },
    error: function(error) {
      response.error(""+error);
    }
  });
});