WITH old_guest_sessions AS (
    SELECT session.id, count(tree.id) AS num_risks
    FROM account, session LEFT JOIN tree
    ON session.id = tree.session_id
    WHERE session.account_id = account.id AND account.account_type = 'guest' AND session.created < current_date - interval '1 week'
    GROUP BY session.id
)
DELETE FROM session USING old_guest_sessions
WHERE old_guest_sessions.id = session.id AND old_guest_sessions.num_risks = 0;

WITH guest_accounts AS (
    SELECT account.id, loginname, count(session.id) AS num_sessions
    FROM account LEFT JOIN session
    ON account.id = session.account_id OR account.id = session.last_modifier_id
    WHERE account_type = 'guest' GROUP BY account.id
)
DELETE FROM account USING guest_accounts
WHERE guest_accounts.id = account.id AND guest_accounts.num_sessions = 0;
