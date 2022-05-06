#! /bin/bash
yum update -y
amazon-linux-extras install docker -y
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user
# install docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.27.4/docker-compose-$(uname -s)-$(uname -m)" \
-o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
mkdir /home/ec2-user/to-do-api && cd /home/ec2-user/to-do-api
cat <<EOF > docker-compose.yaml
version: "3.7"

services:
    todoapp:
        build: .
        restart: always
        ports:
            - "80:3000"
        networks:
            - devenesnet

networks:
    devenesnet:
        driver: bridge
EOF

cat <<EOF > Dockerfile
FROM node:16-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "run", "start"]
EOF

cat <<EOF > package.json
{
  "name": "dummy-nodejs-todo",
  "version": "0.1.1",
  "description": "A simple to do server",
  "main": "index.js",
  "scripts": {
    "start": "node src/index.js",
    "test": "jest src/index.test.js"
  },
  "author": "Devenes",
  "license": "MIT",
  "dependencies": {
    "body-parser": "^1.18.0",
    "ejs": "^2.5.7",
    "express": "^4.15.4",
    "supertest": "^6.2.3"
  },
  "devDependencies": {
    "jest": "^28.0.2"
  }
}
EOF

wget https://raw.githubusercontent.com/devenes/node-js-dummy-test/master/package-lock.json
mkdir /home/ec2-user/to-do-api/src && cd /home/ec2-user/to-do-api/src

cat <<EOF > index.js
//dependencies required for the app
var express = require("express");
var bodyParser = require("body-parser");
var app = express();
const port = process.env.PORT || 3000;


app.use(bodyParser.urlencoded({ extended: true }));
app.set("view engine", "ejs");
//render css files
app.use(express.static("public"));


//placeholders for added task
var task = ["buy a new udemy course", "practise with kubernetes"];
//placeholders for removed task
var complete = ["finish reading the book"];


//post route for adding new task 
app.post("/addtask", function (req, res) {
    var newTask = req.body.newtask;
    //add the new task from the post route
    task.push(newTask);
    res.redirect("/");
});


app.post("/removetask", function (req, res) {
    var completeTask = req.body.check;
    //check for the "typeof" the different completed task, then add into the complete task
    if (typeof completeTask === "string") {
        complete.push(completeTask);
        //check if the completed task already exits in the task when checked, then remove it
        task.splice(task.indexOf(completeTask), 1);
    } else if (typeof completeTask === "object") {
        for (var i = 0; i < completeTask.length; i++) {
            complete.push(completeTask[i]);
            task.splice(task.indexOf(completeTask[i]), 1);
        }
    }
    res.redirect("/");
});


//render the ejs and display added task, completed task
app.get("/", function (req, res) {
    res.render("index", { task: task, complete: complete });
});


//set app to listen on port 3000
app.listen(3000, function () {
    console.log("server is running on port http://localhost:" + port);
});
EOF
mkdir /home/ec2-user/to-do-api/views && cd /home/ec2-user/to-do-api/views

cat <<EOF > index.ejs
<html>

<head>
    <title> To Do App </title>
    <link href="https://fonts.googleapis.com/css?family=Lato:100" rel="stylesheet">
    <link href="/styles.css" rel="stylesheet">
</head>

<body>
    <div class="container">
        <h2> A Simple To-Do List App </h2>

        <form action="/addtask" method="POST">

            <input type="text" name="newtask" placeholder="Add new task">
            <button> Add Task </button>


            <h2> Added Task </h2>

            <% for( var i=0; i < task.length; i++){ %>
                <li><input type="checkbox" name="check" value="<%= task[i] %>" />
                    <%= task[i] %>
                </li>
                <% } %>

                    <button formaction="/removetask" type="submit" id="top" class="button"> Remove </button>
        </form>

        <h2> Completed task </h2>

        <% for(var i=0; i < complete.length; i++){ %>
            <li><input type="checkbox" checked>
                <%= complete[i] %>
            </li>
            <% } %>

    </div>

</body>

</html>
EOF
mkdir /home/ec2-user/to-do-api/public && cd /home/ec2-user/to-do-api/public

cat <<EOF > styles.css
* {
    font-family: sans-serif, Arial, Helvetica, sans-serif;
    font-weight: bold;
}

body {
    background: rgb(0, 0, 0);
    color: #00ffbf;
    margin-top: 20px;
}

.container {
    display: block;
    width: 400px;
    margin: 0 auto;
}

ul {
    margin: 0;
    padding: 0;
}

.button {
    display: block;
    width: 50%;
    height: 30px;
    background: #00ffbf;
    color: rgb(0, 0, 0);
    font-size: 20px;
    text-align: center;
    line-height: 10px;
    cursor: pointer;
}
EOF
cd /home/ec2-user/to-do-api
docker-compose up -d