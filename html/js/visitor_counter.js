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

//increment our visitor counter
xhr.open("PUT", url);

xhr.setRequestHeader("Accept", "application/json");
xhr.setRequestHeader("Content-Type", "application/json");

xhr.onload = () => console.log(xhr.responseText);
xhr.send();
