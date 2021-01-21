import * as functions from "firebase-functions";
import * as admin from 'firebase-admin';
import { Player } from '../structs/player';
import { Room } from '../structs/room';

// // Start writing Firebase Functions
// // https://firebase.google.com/docs/functions/typescript
//
// export const helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

/* admin.initializeApp(functions.config().firebase);

export const playerCreated = functions.firestore
  .document('players/{playerId}')
  .onCreate((snap, context) => {
    // trigger content...
    const playerId = snap.id;
    const player: Player = snap.data;
    const db = admin.firestore();
    return db.runTransaction((trs: FirebaseFirestore.Transaction) => {
        return Rooms.findRoom(db, trs) 
        .then((roomResult: FirebaseFirestore.QuerySnapshot) => {
            var roomId;
            if (roomResult.size == 1) {
                // a room was found, add the player to it
                const roomSnapshot: FirebaseFirestore.DocumentSnapshot = roomResult.docs[0];
                const room: Room = <Room> roomSnapshot.data();
                const players = [...room.players, playerId];
                const newRoomData: Room = { players };
                trs.set(roomSnapshot.ref, newRoomData);
                roomId = roomSnapshot.id;
            } else {
                // no room was found, create a new room with the player
                const players = [playerId];
                const roomRef: FirebaseFirestore.DocumentReference = db.collection('rooms').doc()
                trs.set(roomRef, {players});
                roomId = roomRef.id;
            }
            // then add a reference to the room in the player document
            trs.update(db.collection('players').doc(playerId), { roomId })
        });
    });
  }); */

//class Rooms {
 /**
   * Search a non full room of a specific size
   *
   * @param db The database connection
   * @param trs The transaction in which to execute the request
   * @param size The number of players in the room
   */
   //static findFreeRoom(
      //db: FirebaseFirestore.Firestore,
      //trs: FirebaseFirestore.Transaction,
      //size: number): Promise<FirebaseFirestore.QuerySnapshot> {
      //return trs.get(db.collection('rooms')
        //.where('full', '==', false)
        //.where('size', '==', size)
        //.limit(1));
   //}
//}

//class Rooms {
    /**
      * Search a non full room of a specific size
      *
      * @param db The database connection
      * @param trs The transaction in which to execute the request
      * @param size The number of players in the room
      */
      //static findFreeRoom(
         //db: FirebaseFirestore.Firestore,
         //trs: FirebaseFirestore.Transaction,
         //size: number): Promise<FirebaseFirestore.QuerySnapshot> {
         //return trs.get(db.collection('rooms')
           //.where('full', '==', false)
           //.where('size', '==', size)
           //.limit(1));
      //}
   //}


