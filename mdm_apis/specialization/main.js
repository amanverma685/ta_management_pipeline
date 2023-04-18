'use strict';

const specialization = [
    { id: 1, name: "Data Science" },
    { id: 2, name: "IOT" },
    { id: 3, name: "AI" }
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
        body: JSON.stringify(sendResponse(specialization)),
    };
    callback(null, response);
};