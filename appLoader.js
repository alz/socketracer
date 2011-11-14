   var ss = require('socketstream');     // Initializes the SS global variable

   ss.load();                            // Loads the project files, including the active configuration
   console.log(ss);

   ss.start.single();                    // Start the server in single-process mode (required for Cloud9)

//   ss.redis.connect();                   // Connects to the active instance of Redis, as specified in the config file
