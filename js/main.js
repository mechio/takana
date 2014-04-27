var TESTIMONIALS = [
  {
    avatar_url: 'https://pbs.twimg.com/profile_images/455907502765252608/dtrdnk28_bigger.png',
    body: 'If you don\'t use Takana you\'re wasting your time.',
    url: 'https://twitter.com/christianbundy/status/302836954922364930',
    name: 'Christian Bundy'
  },
  {
    avatar_url: 'https://pbs.twimg.com/profile_images/452731550744866816/U7O_A5fk_bigger.jpeg',
    body: 'Okay, Takana is freaking awesome!',
    url: 'https://twitter.com/_joshnh/status/302724567531651072',
    name: 'Joshua Hibbert'
  },
  {
    avatar_url: 'https://pbs.twimg.com/profile_images/2775698948/bbf0e490c4e400ec8f4d065798fb37ce_bigger.jpeg',
    body: 'Takana is just way too cool',
    url: 'https://twitter.com/prydonius/status/452962303085137920',
    name: 'Adnan Abdulhussein'
  },
  {
    avatar_url: 'https://pbs.twimg.com/profile_images/438863524316471296/7-RoInzh_bigger.jpeg',
    body: 'Takana may be my new favorite tool',
    url: 'https://twitter.com/crswll/status/451186151693758464',
    name: 'Bill Criswell'
  },
  {
    avatar_url: 'https://pbs.twimg.com/profile_images/3585948834/0e5a9a759cee18bb2357f76f462f2526_bigger.jpeg',
    body: 'Pretty impressed by sass live editing with takana',
    url: 'https://twitter.com/zapatoche/status/451290418886742016',
    name: 'Yannick Schall'
  },
  {
    avatar_url: 'https://pbs.twimg.com/profile_images/378800000668585374/5c1e4de92c2db8b281ab6d7a328c2a00_bigger.jpeg',
    body: 'Takana: pretty damn slick.',
    url: 'https://twitter.com/georgebonnr/status/375801941307060224',
    name: 'George Bonner'
  },
  {
    avatar_url: 'https://pbs.twimg.com/profile_images/1472023503/adamj_design_twitter_bigger.jpg',
    body: 'Without a doubt using it on my next project. Takana previews changes *before* you save. It\'s real time as you type.',
    url: 'https://twitter.com/adamj_design/status/401350405017579520',
    name: 'Adam Johnson'
  },
  {
    avatar_url: 'https://pbs.twimg.com/profile_images/2788360549/050aeacf6ebf46fbff70eb55d9d493bf_bigger.png',
    body: 'Saw a live demo of @usetakana last week and I was pretty impressed',
    url: 'https://twitter.com/bengie/status/309665639105167361',
    name: 'Gregory Van Looy'
  }

];

angular.module('takana', [])
       .controller('TestimonialsCtrl', function ($scope){
         $scope.testimonials = TESTIMONIALS;
       });