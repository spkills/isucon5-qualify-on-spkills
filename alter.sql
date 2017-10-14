ALTER TABLE relations ADD INDEX one_createdat(one, created_at);
ALTER TABLE footprints ADD INDEX user_id(user_id);
ALTER TABLE comments ADD INDEX user_id(user_id);

