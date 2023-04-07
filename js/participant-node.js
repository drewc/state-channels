var adjective = ["Excited", "Anxious", "Overweight", "Demonic", "Jumpy", "Misunderstood", "Squashed", "Gargantuan","Broad", "Crooked", "Curved", "Deep", "Even","Excited", "Anxious", "Overweight", "Demonic", "Jumpy", "Misunderstood", "Squashed", "Gargantuan","Broad", "Crooked", "Curved", "Deep", "Even", "Flat", "Hilly", "Jagged", "Round", "Shallow", "Square", "Steep", "Straight", "Thick", "Thin", "Cooing", "Deafening", "Faint", "Harsh", "High-pitched", "Hissing", "Hushed", "Husky", "Loud", "Melodic", "Moaning", "Mute", "Noisy", "Purring", "Quiet", "Raspy", "Screeching", "Shrill", "Silent", "Soft", "Squeaky", "Squealing", "Thundering", "Voiceless", "Whispering"]
var object = ["Taco", "Operating System", "Sphere", "Watermelon", "Cheeseburger", "Apple Pie", "Spider", "Dragon", "Remote Control", "Soda", "Barbie Doll", "Watch", "Purple Pen", "Dollar Bill", "Stuffed Animal", "Hair Clip", "Sunglasses", "T-shirt", "Purse", "Towel", "Hat", "Camera", "Hand Sanitizer Bottle", "Photo", "Dog Bone", "Hair Brush", "Birthday Card"]
var list;

function generator() {
 document.getElementById("name").innerHTML = adjective[Math.floor(Math.random() * adjective.length)] + " " + object[Math.floor(Math.random() * object.length)];;;
}

  function uuidv4() {
    return ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c =>
      (c ^ crypto.getRandomValues(new Uint8Array(1))[0] & 15 >> c / 4).toString(16)
    );
  }

  function ParticipantNode (name = generator(), uuid = uuidv4()) {
    this.selfProposedName = name
    this.uuid = uuid;
    return this;

  }

  export default { ParticipantNode, uuidv4 }
