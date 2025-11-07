// init.js - executed automatically by MongoDB at first startup
print("🏁 Running init.js ...");

const fs = require('fs');

const targetDbList = fs.readFileSync('/etc/abcdesktop/MONGO_DBS_LIST', 'utf8').trim();
const rootUser = fs.readFileSync('/etc/abcdesktop/admin/MONGO_ROOT_USERNAME', 'utf8').trim();
const rootPass = fs.readFileSync('/etc/abcdesktop/admin/MONGO_ROOT_PASSWORD', 'utf8').trim();
const usersStr = fs.readFileSync('/etc/abcdesktop/MONGO_USERS_LIST', 'utf8').trim();

// auth against admin
const adminDb = db.getSiblingDB('admin');
adminDb.auth(rootUser, rootPass);
print('Successfully authenticated admin user');

print('List of database');
print(targetDbList);
const targetDbs = targetDbList.split(',');

for (targetDbStr of targetDbs) {
    print('use ' + targetDbStr);
    // we'll create the users here
    const targetDb = db.getSiblingDB(targetDbStr);
    
    // user-defined roles should be stored in the admin db
    let customRoles = [];
    try {
    const rolesResult = adminDb.getRoles({rolesInfo: 1, showBuiltinRoles: false});
    // Check if rolesResult is an array or an object with a roles property
    if (Array.isArray(rolesResult)) {
        customRoles = rolesResult
        .map(role => role.role)
        .filter(Boolean);
    } else if (rolesResult && rolesResult.roles && Array.isArray(rolesResult.roles)) {
        customRoles = rolesResult.roles
        .map(role => role.role)
        .filter(Boolean);
    }
    print('Custom roles found: ' + JSON.stringify(customRoles));
    } catch (err) {
    print('Warning: Could not retrieve custom roles: ' + err.message);
    customRoles = [];
    }

    // parse the list of users, and create each user as needed
    if (usersStr && usersStr.trim()) {
    usersStr
        .trim()
        .split(';')
        .map(s => s.split(':'))
        .forEach(user => {
        const username = user[0];
        const rolesStr = user[1];
        const password = user[2];

        if (!username || !rolesStr || !password) {
            print('Skipping invalid user entry: ' + JSON.stringify(user));
            return;
        }

        const roles = rolesStr.split(',');
        const userDoc = {
            user: username,
            pwd: password,
        };

        userDoc.roles = roles.map(role => {
            if (customRoles.indexOf(role) === -1) {
            // is this a built-in role?
            return role; // yes, just use the role name
            }
            return {role: role, db: 'admin'}; // no, user-defined, specify the long format
        });

        try {
            print('Creating user: ' + username + ' in database: ' + targetDbStr);
            targetDb.createUser(userDoc);
            print('Successfully created user: ' + username);
        } catch (err) {
            print('Error creating user ' + username + ': ' + err.message);
            if (err.message.toLowerCase().indexOf('duplicate') === -1) {
            // if not a duplicate user
            throw err; // rethrow
            } else {
            print('User ' + username + ' already exists, skipping...');
            }
        }
        });
    } else {
    print('No users to create for database: ' + targetDbStr);
    }
}

print("🏁 init.js completed successfully ✅");
