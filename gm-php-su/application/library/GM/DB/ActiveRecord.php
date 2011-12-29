<?php
class GM_DB_ActiveRecord extends Zend_Db_Table_Abstract
{
    protected $_sPrimary = 'id';

    function __construct( $config = array())
    {
        parent::__construct($config);
    }
}