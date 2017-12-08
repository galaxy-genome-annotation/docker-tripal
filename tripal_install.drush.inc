<?php
function tripal_install_drush_command() {
  $items = array();
  $items['install-prepare'] = array(
    'description' => "Installs Chado and Prepares the Site for docker image.",
    'examples' => array(
      'drush tripal-docker-install',
    ),
    'aliases' => array('tripal-docker-install'),
  );
  return $items;
}

function drush_tripal_install_install_prepare() {
  print_r("Preparing the site by creating content types.\n");
  $prepare = drush_invoke_process('@self', 'php-eval', array("module_load_include('inc', 'tripal_chado', 'includes/setup/tripal_chado.setup'); tripal_chado_prepare_drush_submit();"), array());
  drush_invoke_process('@self', 'php-eval', array("module_load_include('inc', 'tripal', 'tripal.drush'); drush_tripal_trp_run_jobs_install('" . getenv('ADMIN_USER') . "');"), array());
  if (!$prepare) {
    echo "An error occurred when attempting to install Chado. Please navigate to your new site and finish the installation process from the 'Install Tripal' section as described in the online help, found here http://tripal.info/tutorials/v3.x/installation/tripal \n";
    exit;
  }

  //Get all the content types and add the permissions.
  drush_print(dt(""));
  print_r("Adding permissions for the administrator to view, edit, create, and delete all the newly created content types.\n");
  $permissions = array();
  $bundles = tripal_get_content_types();
  foreach($bundles as $bundles=>$bundle){
    array_push($permissions, ' view ' . $bundle->name, ' create ' . $bundle->name,
      ' edit ' . $bundle->name,  ' delete ' . $bundle->name);
  }
  $string_permissions = implode(",", $permissions);
  $args4 = array('administrator', $string_permissions);
  $options4 = array();
  drush_invoke_process('@self', 'role-add-perm', $args4, $options4);

  //Get all the content types and add the anonymous permissions.
  drush_print(dt(""));
  print_r("Adding permissions for anonymous user to view all the newly created content types.\n");
  $permissions = array();
  $bundles = tripal_get_content_types();
  foreach($bundles as $bundles=>$bundle){
    array_push($permissions, ' view ' . $bundle->name);
  }
  $string_permissions = implode(",", $permissions);
  $args4 = array('anonymous user', $string_permissions);
  $options4 = array();
  drush_invoke_process('@self', 'role-add-perm', $args4, $options4);

  //Get all the content types and add the anonymous permissions.
  drush_print(dt(""));
  print_r("Adding permissions for authenticated users to view all the newly created content types.\n");
  $permissions = array();
  $bundles = tripal_get_content_types();
  foreach($bundles as $bundles=>$bundle){
    array_push($permissions, ' view ' . $bundle->name);
  }
  $string_permissions = implode(",", $permissions);
  $args4 = array('authenticated user', $string_permissions);
  $options4 = array();
  drush_invoke_process('@self', 'role-add-perm', $args4, $options4);

  drush_print(dt(""));
  drush_print(dt("Installation is now complete. You may navigate to your new site. For more information on using Tripal please see the installation guide on tripal.info."));
}
