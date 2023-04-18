'use strict';

const departments = [
    { id: 1, name: "Aerospace and Ocean Engineering" },
    { id: 2, name: "Biological Systems Engineering" },
    { id: 3, name: "Biomedical Engineering and Mechanics" },
    { id: 4, name: "Chemical Engineering" },
    { id: 5, name: "Civil and Environmental Engineering" },
    { id: 6, name: "Computer Science" },
    { id: 7, name: "Electrical and Computer Engineering" },
    { id: 8, name: "Engineering Education" },
    { id: 9, name: "Industrial and Systems Engineering" },
    { id: 10, name: "Materials Science and Engineering" },
    { id: 11, name: "Mechanical Engineering" }
]

function sendResponse(body) {
    return {
        "responseData": body,
        "success": true
    }
}

exports.handler = function (event, context, callback) {
    var response = {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*'
        },
        body: JSON.stringify(sendResponse(departments)),
    };
    callback(null, response);
};