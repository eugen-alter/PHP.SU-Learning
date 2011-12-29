<?php
class GM_Controller_Base extends Zend_Controller_Action
{
    protected $_rDb = null;

    public function init()
    {
        $this->_rDb = new GM_DB_ActiveRecord();
    }
    
    public function postDispatch()
    {
        $this->getResponse()->setHeader('Content-Type', 'text/html; charset=UTF-8', true);
        $this->getResponse()->setHeader('Pragma', 'no-cache', true);
    }
}

?>
