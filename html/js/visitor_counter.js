const counter = document.getElementById("visit_count");
const url = "https://api.ad3f.me/stats/visit-count/";
let xhr = new XMLHttpRequest();

//begin fetching our visitor count using our API
fetch(url)
  .then((res) => {
    return res.json();
  })
  .then((data) => {
    const res = data;
    counter.textContent = Number(res.body.visit_count);
  });
