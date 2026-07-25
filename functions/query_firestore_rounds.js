const https = require("https");
const API_KEY = "AIzaSyChJ_be6rHgJ1q8VjTUmuqpI2N-ZwX-tk4";
const url = `https://firestore.googleapis.com/v1/projects/lottery-advance/databases/(default)/documents/rounds?pageSize=50&key=${API_KEY}`;

https.get(url, (r) => {
  let data = "";
  r.on("data", (c) => (data += c));
  r.on("end", () => {
    const docs = JSON.parse(data).documents || [];
    for (const doc of docs) {
      const roundId = doc.name.split("/").pop();
      const f = doc.fields;
      const lv = parseInt(roundId.slice(-2));
      if (lv < 10 || lv > 13) continue;
      const cfg = f.config.mapValue.fields;
      const winnerCellsVal = f.winningCells?.arrayValue?.values;
      const winnerCells = winnerCellsVal
        ? winnerCellsVal.map((v) => v.stringValue || v.integerValue)
        : [];
      console.log(
        `L${lv} (${roundId}): maxWinners=${cfg.maxWinners.integerValue} winningCells=${JSON.stringify(winnerCells)}`
      );
    }
  });
}).on("error", (e) => console.error(e));
