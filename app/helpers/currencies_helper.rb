module CurrenciesHelper
  def default_mutual_credit_currency(taxable=true,unit='USD')
    currency_spec = {}
    currency_spec['fields'] = {
      'amount' => {
        'type' => 'float',
        'description' => {
          'en' => 'Amount',
          'es' => 'Cantidad',
          'fr' => 'Quantité'
        }
      },
    	'description' => {
        'type' => 'text',
        'description' => {
          'en' => 'Description',
          'es' => 'Descripción',
          'fr' => 'Description'
        }
      },
    	'acknowledge_flow' => {
        'type' => 'submit',
        'description' => {
          'en' => 'Acknowledge Flow',
          'es' => 'Reconoce el Flujo',
          'fr' => 'Confirmer la Transaction'
        }
    	},
    	unit => 'unit'
    }
    currency_spec['fields']['taxable'] = {
      'type' => 'boolean',
      'description' => {
        'en' => 'Taxable',
        'es' => 'Ingreso Imponible',
        'fr' => 'Imposable',
      },
      'values_enum' => {
        'en' => [['Yes','true'],['No','false']],
        'es' => [['Si','true'],['No','false']],
        'fr' => [['Oui','true'],['Non','false']]
      }
    } if taxable
  	currency_spec['summary_type'] = 'balance(amount)'
  	currency_spec['input_form'] = {
  	  'en' => ":declaring_account acknowledges :accepting_account for :description in the amount of :amount #{taxable ? '(taxable :taxable) ' : ''}:acknowledge_flow",
      'es' => ":declaring_account reconoce :accepting_account por :description en la cantidad de :amount #{taxable ? '(ingreso imponible :taxable) ' : ''} :acknowledge_flow",
  	  'fr' => ":declaring_account remercie :accepting_account pour :description et lui verse la somme de :amount #{taxable ? '(imposable :taxable) ' : ''}:acknowledge_flow"
  	}
  	currency_spec
  end
end
