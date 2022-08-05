const stopwords = require("./stopwords");
const functions = require("firebase-functions");
const admin = require('firebase-admin');
const request = require('request');
const malsecrets = require('./malsecrets');
const { promisify } = require('util')

admin.initializeApp();

//add creates a new id
//admin.firestore().collection('moods').doc("").create() creates a doc with given name if doesn't exist
//admin.firestore().collection('moods').doc("").update() updates field of doc if doc exists
//admin.firestore().collection('moods').doc("").set() creates doc and field of doc
//const writeResult = await admin.firestore().collection('moods').add({original: original});
//res.json({result: `Mood withs ID: ${writeResult.id} added.`});
  
// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
exports.helloWorld = functions.https.onRequest((request, response) => {
  functions.logger.info("Hello logs!", {structuredData: true});
  response.send("Hello from Firebase!" + firebase.auth().currentUser.getIdToken(true)
  .then(function (token) {
    response.send("bla ", token)
    // You got the user token
  }));
  response.sen
});

const sleep = promisify(setTimeout)

const admuser = "MZTirerp0cRhybu1W4VJtJJB37G2"
exports.loadUserAnime = functions.https.onRequest(async (req, res) => {
  //var reqstr = req.body.toString().replace(" ", "").trim();
  var reqstr = req.body.toString().replace(/(['"])?([a-z0-9A-Z_]+)(['"])?:/g, '"$2": ');
  console.log("body is: ", reqstr);
  var reqjs = JSON.parse(reqstr);
  console.log("reqjs: ", reqjs);
  var malname = reqjs["maluser"];
  var useruid = reqjs["useruid"];
  headers = {
    "accept": "application/json", 
    "content-type": "application/json",
    "X-MAL-CLIENT-ID": "296ad33f52bd54e88a8a2b10741795db"
  };
  var reqOptions = {
    url: 'https://api.myanimelist.net/v2/users/'+malname+'/animelist?limit=10&sort=list_score&fields=list_status', 
    headers: headers, 
    method: "GET", 
    //body: data, 
    json: true
  };

  // console.log("reqUrl: ", reqUrl);
  await request(reqOptions, async (error, response, body) => {
    if(error) res.status(response).send(error, " ", body);
    else {
      console.log("body: ", body);
      //var animejson = body.toString().replace(/(['"])?([a-z0-9A-Z_]+)(['"])?:/g, '"$2": ');
      //console.log("animejson: ", animejson);
      jsondata = body["data"] // JSON.parse(animejson)["data"];
      for(var i=0; i<jsondata.length; ++i) {
        var jsonel = jsondata[i]
        var malid = jsonel["node"]["id"];
        var title = jsonel["node"]["title"];
        var pic = jsonel["node"]["main_picture"]["medium"];
        var mooddocumentname = 'Anime_' + malid.toString().padStart(8, '0') + "_" + admuser + "_0";
        var rating = jsonel["list_status"]["score"]; // same as mood dex
        var status = jsonel["list_status"]["status"];
        // ["Watching", "Completed", "Plan to watch", "Dropped", "On Hold"]
        var ca = status == "watching" ? 0 : status == "completed" ? 1 : status == "plan_to_watch" ? 2 : status == "dropped" ? 3 : status == "on_hold" ? 4 : 4;
        console.log("Adding ", mooddocumentname)
        var doc = admin.firestore().collection("users").doc(useruid).collection("mymoods").doc(mooddocumentname);
        doc.set({
          "ca": ca,
          "cn": mooddocumentname,
          "dr": "/moods/" + mooddocumentname,
          "gu": "",
          "im": pic,
          "na": title,
          "ra": rating,
          // anime specific
          "mid": malid
        });
      }
    }  
  })
});

exports.importallanime = functions.https.onRequest(async (req,res) => {
  for(var no=1;no<=1;++no) {
    // console.error(no);
    //console.error('https://api.jikan.moe/v3/top/anime/'+no+'/bypopularity');
    try {
      await request('https://api.jikan.moe/v3/top/anime/'+no+'/bypopularity', async (error, response, body) => {
      var waitingOn = [];
      if(error) reject(error)
      else {
        // const wstream = fs.createWriteStream('./out/'+no.toString().padStart(4,"0")+'.txt', {encoding: 'utf8'});
        jsontop = JSON.parse(body)['top'];
        if (jsontop == null) {
          respose.send(body);
        }
        
        //console.err(jsontop.length);
        //console.log(jsontop)
        var out = "";
        for(var i=0;i<jsontop.length; i++) {
          //console.error(jsontop[i])
          console.log(jsontop[i]['url']);
          mal_id = jsontop[i]['mal_id'];
          start_date = jsontop[i]['start_date'];
          if(start_date == null) {
            res.send("no start date: " + jsontop[i]['url'] + ' ' + jsontop[i]['title']);
            continue; //skip unreleased anime
          }
          sd = start_date.split(' ');
          md = new Map();
          md.set('Jan', 0);
          md.set('Feb', 1);
          md.set('Mar', 2);
          md.set('Apr', 3);
          md.set('May', 4);
          md.set('Jun', 5);
          md.set('Jul', 6);
          md.set('Aug', 7);
          md.set('Sep', 8);
          md.set('Oct', 9);
          md.set('Nov', 10);
          md.set('Dec', 11);
          d = new Date(sd[1], md.get(sd[0]),1,1);
          unixTime = Math.floor(d / 1000);
          if(unixTime < 0) unixTime = 0;
          image_url = jsontop[i]['image_url'];
          imgurls = image_url.split('?');
          imgurls[0] = imgurls[0].substring(0, imgurls[0].length-4 ) + 'l' + imgurls[0].substring(imgurls[0].length-4 ) ;
          
          var search_terms = [];
          var words = jsontop[i]["title"].split(" ");
          for(var word of words) {
            word = word.toLowerCase().toUpperCase().toLowerCase();
            if(!(word in stopwords)) {
              for(var j=3;j<=word.length;j++) {
                search_terms.push(word.substring(0,j));
              }
            }
          }
          search_terms.push("anime");
          search_terms.push(mal_id.toString());
          
          var mooddocumentname = 'Anime_' + mal_id.toString().padStart(8, '0') + "_" + admuser + "_0";
          // jsontop[i]["title"].toLowerCase().toUpperCase().toLowerCase().split(" ").join("_") + '_' + admuser + '_0';
          //use .create in the future as it will fail if the document exists already.
          waitingOn.push( admin.firestore().collection('moods').doc(mooddocumentname).set({
            author: admuser,
            image_ref: imgurls[0],
            link: jsontop[i]['url'],
            location: "",
            mal_id: mal_id,
            mal_members: jsontop[i]['members'],
            mal_rank: jsontop[i]['rank'],
            mal_score: jsontop[i]['score'],
            name: jsontop[i]['title'],
            rnd: 0,
            search_terms: search_terms,
            searchable: true,
            ts: unixTime,
            type: 1, //1=anime
            votes_0: 0,
            votes_1: 0,
            votes_2: 0,
            votes_3: 0,
            votes_4: 0,
            votes_5: 0,
            votes_6: 0,
            votes_7: 0,
            votes_8: 0,
            votes_9: 0,
            votes_10: 0,
          }) );
        }
        await waitingOn.forEach(async (val) => await val);
        console.log("finished page " + no);
      }
    })
  }
  catch(onError) {
    res.send("Error: " + no.toString() + ': ' + onError.toString());
  }
  await sleep(5000); //have to wait min 4 secs between requests to jikan js
}
});




