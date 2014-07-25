/*****************************
 * Author: Jimages
 * Date: Jul 26,2014
 * Description:
 *  Implementation of base64 for mysql.
 *****************************
 */
DELIMITER //
/*****************************
 * @base64_encode ( code TEXT)
 * Description:
 *  Implementation of base64 encode for mysql 5.1
 * Parameter:
 *   code TEXT   Source code which is needed to encode.
 *****************************
 */
-- We drop function if exists.
DROP FUNCTION IF EXISTS base64_encode //
CREATE FUNCTION  base64_encode (code TEXT)
RETURNS  TEXT
COMMENT 'Encode base64'
BEGIN
    -- Establish base64 table.
    SET @base64_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    SET @bit_width = BIT_LENGTH(code);
    SET @base64_code = '';
    SET code = HEX(code);
    IF @bit_width MOD 8 != 0 THEN
        RETURN NULL;
    END IF;
    WHILE @bit_width != 0 DO

        -- If there is more than 3 bytes.
        IF @bit_width >= 24 THEN
            -- We save 3 bytes to buffer.
           SET @buffer = SUBSTRING(code,1,6);
           SET code = SUBSTRING(code,7);
            -- Now we get bit of 3 chars.
           SET @which_code = 1;
           SET @each_code = 0;
           WHILE @which_code <= 6  DO
                SET @each_code := @each_code << 8;
                SET @each_code := @each_code | ASCII(UNHEX(SUBSTRING(@buffer,@which_code,2)));
                SET @which_code = @which_code + 2;
            END WHILE; 

            -- Now we get chars of base64.
            SET @which_code = 0;
            SET @group_base64_code := '';
            WHILE @which_code < 4 DO
                SET @base64_char_num = (@each_code & 63); -- 63 for 0111111
                SET @base64_char = SUBSTRING(@base64_table,@base64_char_num +1 , 1); 
                -- We get char from end to begining.
                SET @group_base64_code = CONCAT(@base64_char,@group_base64_code);
                SET @each_code = @each_code >> 6; 
                SET @which_code := @which_code + 1;
            END WHILE;
            SET @base64_code = CONCAT(@base64_code,@group_base64_code);
            SET @bit_width = @bit_width - 24;


        -- If there is less 3 bytes.
        ELSEIF @bit_width > 0 && @bit_width < 24 THEN

            -- If there is 1 bytes.
            IF (@bit_width / 8) = 1 THEN
                SET @buffer = ASCII(UNHEX(code)); 
                SET @each_code = @buffer << 4 ;
                SET @which_code = 0;
                SET @group_base64_code = '';
                WHILE @which_code < 2 DO
                    SET @base64_char_num = (@each_code & 63); -- 63 for 0111111
                    SET @base64_char = SUBSTRING(@base64_table,@base64_char_num +1 , 1); 
                    -- We get char from end to begining.
                    SET @group_base64_code = CONCAT(@base64_char,@group_base64_code);
                    SET @each_code = @each_code >> 6; 
                    SET @which_code := @which_code + 1;
                END WHILE;
                SET @base64_code = CONCAT(@base64_code,@group_base64_code,'==');
                SET @bit_width = @bit_width - 8;
 

            -- If there is 2 bytes.
            ELSEIF (@bit_width / 8) = 2 THEN
                SET @buffer = code;
            
                -- Now we get bit of 2 chars.
                SET @which_code = 1;
                SET @each_code = 0;
                WHILE @which_code <= 4 DO
                    SET @each_code := @each_code << 8;
                    SET @each_code := @each_code | ASCII(UNHEX(SUBSTRING(@buffer,@which_code,2)));
                    SET @which_code = @which_code + 2;
                END WHILE; 
                SET @each_code := @each_code << 2;

                -- Now we get chars of base64.
                SET @which_code := 0;
                SET @group_base64_code := '';
                WHILE @which_code < 3 DO
                    SET @base64_char_num = (@each_code & 63); -- 63 for 0111111
                    SET @base64_char = SUBSTRING(@base64_table,@base64_char_num +1 , 1); 
                    -- We get char from end to begining.
                    SET @group_base64_code = CONCAT(@base64_char,@group_base64_code);
                    SET @which_code := @which_code + 1;
                    SET @each_code = @each_code >> 6;
                END WHILE;
                SET @base64_code = CONCAT(@base64_code,@group_base64_code,'=');
                SET @bit_width = @bit_width - 16;
            END IF;
         ELSE 
            RETURN NULL;
         END IF;
    END WHILE;
    RETURN @base64_code;
END
//
/*****************************
 * @base64_decode ( code TEXT)
 * Description:
 *  Implementation of base64 decode for mysql 5.1
 * Parameter:
 *   code TEXT   Encoded code which is needed to decode.
 *****************************
 */
-- We drop function if exists.
DROP FUNCTION IF EXISTS base64_decode;
CREATE FUNCTION  base64_decode (code TEXT)
RETURNS  TEXT
COMMENT 'Decode base64'
BEGIN
    DECLARE bit_width INTEGER;
    -- Establish base64 table.
    SET @base64_table = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    -- Remove all '='
    IF BIT_LENGTH(code) % 32 != 0 THEN
        RETURN NULL;
    END IF;
    SET code = REPLACE(code,'=','');
    SET @source_code = '';
    SET @bit_width = BIT_LENGTH(code);
    -- For wrong base64 char.
    WHILE @bit_width != 0 DO
        
        -- If there is more than 4 chars.
        IF @bit_width >= 32 THEN
            SET @buffer = SUBSTRING(code,1,4);
            SET code = SUBSTRING(code,5);
            SET @which_code = 1;
            SET @each_code = 0;

            -- We get bits of 4 chars
            WHILE @which_code <= 4 DO
                SET @each_code = @each_code << 6;
                SET @each_code = @each_code | (BIT_LENGTH(SUBSTRING_INDEX(@base64_table,SUBSTRING(@buffer,@which_code,1),1))/8);
                SET @which_code = @which_code + 1;
            END WHILE; 

            -- Convert to HEX
            SET @which_code = 1;
            SET @buffer = '';
            WHILE @which_code <=6  DO
               SET @buffer = CONCAT(SUBSTRING('0123456789ABCDEF',(@each_code & 15)+1,1),@buffer);  -- 15 for 01111
               SET @each_code = @each_code >> 4;
               SET @which_code = @which_code + 1;
            END WHILE;

            -- We save it into source_code.
            SET @source_code = CONCAT(@source_code,@buffer);
            SET @bit_width = @bit_width - 32; -- This bits is for base64_encoded string.

        -- For 2 byte base64 char ( 1 source char).
        ELSEIF @bit_width = 16 THEN
            SET @buffer = code;
            SET @each_code = 0;
            SET @which_code = 1;

            -- We get bits of 2 base64 chars.
            WHILE @which_code <= 2 DO
                SET @each_code = @each_code << 6;
                SET @each_code = @each_code | (BIT_LENGTH(SUBSTRING_INDEX(@base64_table,SUBSTRING(@buffer,@which_code,1),1))/8);
                SET @which_code = @which_code + 1;
            END WHILE; 

            -- We remove filled bits.
            SET @each_code = @each_code >> 4;

            -- Convert to HEX
            SET @which_code = 1;
            SET @buffer = '';
            WHILE @which_code <=2  DO
               SET @buffer = CONCAT(SUBSTRING('0123456789ABCDEF',(@each_code & 15)+1,1),@buffer);  -- 15 for 01111
               SET @each_code = @each_code >> 4;
               SET @which_code = @which_code + 1;
            END WHILE;

            -- We save it into source_code.
            SET @source_code = CONCAT(@source_code,@buffer);
            SET @bit_width = @bit_width - 16; -- This bits is for base64_encoded string.

        -- For 3 base64 chars (2 source chars).
        ELSEIF @bit_width = 24 THEN 
            SET @buffer = code;
            SET @each_code = 0;
            SET @which_code = 1;

            -- We get bits of 3 base64 chars.
            WHILE @which_code <= 3 DO
                SET @each_code = @each_code << 6;
                SET @each_code = @each_code | (BIT_LENGTH(SUBSTRING_INDEX(@base64_table,SUBSTRING(@buffer,@which_code,1),1))/8);
                SET @which_code = @which_code + 1;
            END WHILE; 

            -- We remove filled bits.
            SET @each_code = @each_code >> 2;

            -- Convert to HEX
            SET @which_code = 1;
            SET @buffer = '';
            WHILE @which_code <= 4 DO
               SET @buffer = CONCAT(SUBSTRING('0123456789ABCDEF',(@each_code & 15)+1,1),@buffer);  -- 15 for 01111
               SET @each_code = @each_code >> 4;
               SET @which_code = @which_code + 1;
            END WHILE;

            -- We save it into source_code.
            SET @source_code = CONCAT(@source_code,@buffer);
            SET @bit_width = @bit_width - 24; -- This bits is for base64_encoded string.
        ELSE
            -- For wrong base64 code.
            RETURN NULL;
        END IF;
    END WHILE;
    RETURN UNHEX(@source_code);
END
//
DELIMITER ;
