exports.config =

 log:
   level: 0

 client:
   log:
     level: 0

   map:
     name: "map1"
     tile_width: 512
     tile_height: 512
     tile_count: 70
     sprite: "/images/asphaltsprite.jpg"
     tiles: [
       [[1,0], [1,0], [1,0], [2,52], [3,51], [0,0], [0,0], [0,0], [0,0], [0,0]],
       [[1,0], [1,0], [1,0], [4,53], [4,50], [11,27], [5,26], [5,25], [5,24], [10,23]],
       [[1,0], [1,0], [1,0], [4,54], [4,49], [4,28], [1,0], [1,0], [1,0], [4,22]],
       [[2,58], [5,57], [5,56], [13,55], [4,48], [4,29], [1,0], [2,19], [5,20], [13,21]],
       [[7,59], [3,60], [2,43], [3,44], [4,47], [4,30], [1,0], [4,18], [2,11], [3,10]],
       [[2,62], [6,61], [4,42], [12,45], [13,46], [7,31], [10,32], [4,17], [4,12], [4,9]],
       [[4,63], [0,0], [4,41], [0,0], [0,0], [0,0], [4,33], [4,16], [4,13], [4,8]],
       [[4,64], [0,0], [4,40], [0,0], [0,0], [0,0], [4,34], [7,15], [6,14], [4,7]],
       [[4,65], [0,0], [7,39], [5,38], [5,37], [5,36], [6,35], [11,4], [5,5], [6,6]],
       [[7,66], [5,67], [5,68], [5,69], [5,70], [8,1], [5,2], [6,3], [0,0], [0,0]]
     ]
			
 browser_check:
   enabled: true
   strict: true