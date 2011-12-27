<?
class DeepController extends GM_Controller_Base
{
    function init()
    {
        parent::init();
    }

    function indexAction()
    {

    }

    function testAction()
    {
	$this->view->message='Test message';
    }
}
