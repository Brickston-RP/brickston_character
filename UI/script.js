// slider

const height=document.getElementById("height");
const heightValue=document.getElementById("heightValue");

height.oninput=()=>{
heightValue.textContent=height.value;
};

// genre toggle

$(".gender-btn").click(function(){
$(".gender-btn").removeClass("active");
$(this).addClass("active");
});

// dropdown

$(".dropdown-selected").click(function(){
$(this).parent().toggleClass("open");
});

$(".option").click(function(){

let text=$(this).text();

$(this)
.closest(".dropdown")
.find("span")
.text(text);

$(".dropdown").removeClass("open");

});

$(document).click(function(e){
if(!$(e.target).closest(".dropdown").length){
$(".dropdown").removeClass("open");
}
});
