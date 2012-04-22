/* Handles:
 *   Ringing the doorbell
 *   Pull info, and find if it's current or not
 *   If you ring and it returns false, then update the view
 */

var last_ring = false;
var msg = "Oops! The ringer is having some difficulties, maybe you \
should try again in a minute?";

$(document).ready(function(){
    $("#ringer").click(function(e) {
        if (last_ring && (new Date()) - last_ring.getTime() < 30000)  {
            console.log("too soon");
            return;
        }
        last_ring = new Date();
        $.ajax({url: "/ring",
                dataType: "json",
                success:function(data, status, XHR) {
                    if(!data["current"]) {
                        location.reload();
                    } else if(!data["ring"]) {
                        alert(msg);
                    }
                }
               });
        alert("Alright, hold tight, someone should be coming by soon!");
    });
});
