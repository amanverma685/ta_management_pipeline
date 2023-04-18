const pg = require('pg')
const pool = new pg.Pool({
    host: 'vt-survey-database.copaymbev82s.us-east-2.rds.amazonaws.com',
    user: 'postgres',
    password: 'admin123',
    port: '5432',
    database: 'vt_survey_management'
})

async function query(q) {
    const client = await pool.connect()
    let res
    try {
        await client.query('BEGIN')
        try {
            res = await client.query(q)
            await client.query('COMMIT')
        } catch (err) {
            await client.query('ROLLBACK')
            throw err
        }
    } finally {
        client.release()
    }
    return res
}

function getResponse(data, success, message = "") {
    return JSON.stringify({
        "responseData": data,
        "success": success,
        "message": "Success"
    })
}

function getWhereClause(fields) {
    var whereclause = "WHERE 1=1"
    for (var field in fields) {
        switch (field) {
            case "surveyId": whereclause = whereclause + ` AND survey_id = '${fields[field]}'`
                break;
            case "startDate": whereclause = whereclause + ` AND start_date >= TO_DATE('${fields[field]}', 'YYYY-MM-DDTHH24:MI:SSZ')`
                break;
            case "endDate": whereclause = whereclause + ` AND expiry_date <= TO_DATE('${fields[field]}', 'YYYY-MM-DDTHH24:MI:SSZ')`
                break;
            case "surveyStatus": whereclause = whereclause + ` AND survey_status = '${fields[field]}'`
        }
    }
    return whereclause
}

exports.handler = async (event, context) => {
    try {
        const q = `SELECT * from surveys ${getWhereClause(JSON.parse(event.body))}`
        console.log(q)
        const { rows } = await query(q)
        var response = {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": getResponse(rows, true),
            "isBase64Encoded": false
        };
        return response
    } catch (err) {
        console.log(err)
        var response = {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json"
            },
            "body": getResponse([], false, err.message),
            "isBase64Encoded": false
        };
        return response
    }
};